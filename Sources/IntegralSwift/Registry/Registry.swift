//
//  Registry.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

// The dependency injection container that contains all service definitions.
public final class Registry {

    // MARK: - SETTINGS

    /// Prints all registered services after registry has started
    public static var printServicesOnStartup: Bool = true

    /// Prints all registered services after registry has started
    public static var defaultServiceRealizationType: ServiceRealizationType = .injection

    // MARK: - PRIVATE PROPERTIES

    private static var instance = Registry()

    private let registrationQueue = DispatchQueue(label: "integral-registry.registrationQueue",
                                                  attributes: .concurrent)
    private var _serviceDefinitions = [String: Any]()
    private var serviceDefinitions: [String: Any] {
        get {
            self.registrationQueue.sync {
                self._serviceDefinitions
            }
        }
        set {
            self.registrationQueue.async(flags: .barrier) {
                self._serviceDefinitions = newValue
            }
        }
    }

    private var _overrideDefinitions = [String: Any]()
    private var overrideDefinitions: [String: Any] {
        get {
            self.registrationQueue.sync {
                self._overrideDefinitions
            }
        }
        set {
            self.registrationQueue.async(flags: .barrier) {
                self._overrideDefinitions = newValue
            }
        }
    }

    private static var availableModuleIdentifiers = Set<String>()

    // MARK: - MUTEX

    private static var registryMutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()

    private static var resolveMutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()

    // MARK: - REGISTRATION METHODS (PUBLIC)

    /// Registers a service. Warns if service is already registered. Will be registered anyway.
    ///
    /// - parameter type: Optional service type, may be inferred. Should be used for specialization.
    /// - parameter factory: Closure that returns the actual service
    ///
    /// - returns: ServiceOptions for further configuration.
    @discardableResult
    public static func register<S>(_ type: S.Type = S.self,
                                   factory: @escaping Factory<S>) -> ServiceOptions {
        self.instance.register(type, factory: factory)
    }

    /// Override a service. Warns if service is niot registered. Will be overridden/registered anyway.
    ///
    /// - parameter type: Optional service type, may be inferred. Should be used for specialization.
    /// - parameter factory: Closure that returns the actual service
    ///
    /// - returns: ServiceOptions for further configuration.
    @discardableResult
    public static func override<S>(_ type: S.Type = S.self,
                                   factory: @escaping Factory<S>) -> ServiceOptions {
        self.instance.override(type, factory: factory)
    }

    /// Registers a service as lazy. Warns if service is already registered. Will be registered anyway.
    ///
    /// - parameter type: Optional service type, may be inferred. Should be used for specialization.
    /// - parameter factory: Closure that returns the actual service
    ///
    /// - returns: ServiceOptions for further configuration.
    @discardableResult
    public static func lazy<S>(_ type: S.Type = S.self,
                               factory: @escaping Factory<S>) -> ServiceOptions {
        self.instance.register(type, factory: factory).lazy()
    }

    /// Registers a service as eager loaded. Warns if service is already registered. Will be registered anyway.
    ///
    /// - parameter type: Optional service type, may be inferred. Should be used for specialization.
    /// - parameter factory: Closure that returns the actual service
    ///
    /// - returns: ServiceOptions for further configuration.
    @discardableResult
    public static func eager<S>(_ type: S.Type = S.self,
                                factory: @escaping Factory<S>) -> ServiceOptions {
        self.instance.register(type, factory: factory).eager()
    }

    // MARK: - REGISTRATION METHODS (PRIVATE)

    private func register<S>(_ type: S.Type = S.self,
                             factory: @escaping Factory<S>) -> ServiceDefinition<S> {

        let fqsn = String(reflecting: type)

        if let alreadyRegistered = self.serviceDefinitions[fqsn] as? ServiceBaseDefinition {
            // swiftlint:disable line_length
            print("⚠️ WARNING: Service '\(alreadyRegistered.typeName)' is already registered and will be overriden by '\(fqsn)'. Use 'Registry.override(...)' to silence this warning.")
        }

        let definition = ServiceDefinition(type: type,
                                           factory: factory)

        self.serviceDefinitions[fqsn] = definition

        return definition
    }

    private func override<S>(_ type: S.Type = S.self,
                             factory: @escaping Factory<S>) -> ServiceDefinition<S> {

        let fqsn = String(reflecting: type)

        if self.overrideDefinitions[fqsn] != nil {
            print("⚠️ WARNING: Service '\(fqsn)' is already overriden. Previous override will be ignored.")
        }

        let definition = ServiceDefinition(type: type,
                                           isOverride: true,
                                           factory: factory)

        self.overrideDefinitions[fqsn] = definition

        return definition
    }

    // MARK: - STARTUP

    private typealias RegistryStartupFn = () -> Void

    private static var startRegistryOnce: RegistryStartupFn? = Registry.startRegistry

    private static var isStarted: Bool {
        Registry.startRegistryOnce == nil
    }

    private static func startRegistry() {
        pthread_mutex_lock(&Registry.registryMutex)

        // Make sure we haven't run registry startup yet
        guard Registry.isStarted == false,
              let registrations = (Registry.instance as Any) as? RegistryModule else {
                  pthread_mutex_unlock(&Registry.registryMutex)
                  return
              }

        // We need to set it nil before actually registering the services,
        // eager loading might crash due to not finishing register first.
        Registry.startRegistryOnce = nil

        let allModules = analyze(modules: [type(of: registrations)])

        // Registers all the services
        allModules.forEach { $0.onStartup() }

        // Override services
        for (_, overrideTuple) in Registry.instance.overrideDefinitions.enumerated() {
            guard let overrideDefinition = overrideTuple.value as? ServiceBaseDefinition else {
                continue
            }

            if Registry.instance.serviceDefinitions[overrideTuple.key] == nil {
                print("⚠️ WARNING: Overriden unregistered Service '\(overrideDefinition.typeName)'. Use Registry.register(...) instead.")
            }

            Registry.instance.serviceDefinitions[overrideTuple.key] = overrideDefinition
        }

        pthread_mutex_unlock(&Registry.registryMutex)

        eagerLoadServices()

        if Registry.printServicesOnStartup {
            printServices()
        }

        allModules.forEach { $0.afterStartup() }
    }

    private static func analyze(modules: [RegistryModule.Type]) -> [RegistryModule.Type] {
        guard modules.isEmpty == false else {
            return []
        }

        var analyzedModules: [RegistryModule.Type] = []

        for module in modules {

            let moduleName = String(reflecting: module)

            if self.availableModuleIdentifiers.contains(moduleName) {
                print("ℹ️ Module '\(moduleName)' is already imported.")
                continue
            }

            analyzedModules.append(module)
            self.availableModuleIdentifiers.insert(moduleName)

            let importedModules = analyze(modules: module.imports())
            analyzedModules.append(contentsOf: importedModules)
        }

        return analyzedModules
    }

    private static func shutdownRegistry() {
        pthread_mutex_lock(&Registry.registryMutex)

        // Make sure we haven't run registry startup yet

        guard Registry.isStarted,
              Registry.instance.serviceDefinitions.isEmpty == false,
              let registrations = (Registry.instance as Any) as? RegistryModule else {
                  pthread_mutex_unlock(&Registry.registryMutex)
                  return
              }

        shutdown(modules: [type(of: registrations)])

        for maybeDef in Registry.instance.serviceDefinitions {

            if var def = maybeDef.value as? ServiceBaseDefinition {
                def.isActive = false
            }
        }

        Registry.instance.serviceDefinitions = [String: Any]()
        Registry.instance.overrideDefinitions = [String: Any]()
        Registry.availableModuleIdentifiers = Set<String>()
        Registry.startRegistryOnce = Registry.startRegistry

        pthread_mutex_unlock(&Registry.registryMutex)
    }

    private static func shutdown(modules: [RegistryModule.Type]) {
        for module in modules {
            let moduleImports = module.imports()
            shutdown(modules: moduleImports)
            module.onShutdown()
        }
    }

    private static func eagerLoadServices() {
        // Eager Load services
        for rawDefinition in Registry.instance.serviceDefinitions.values {
            guard let serviceOptions = rawDefinition as? ServiceOptions,
                  serviceOptions.realizationType == .eager,
                  let serviceDefinition = rawDefinition as? ServiceBaseDefinition else {
                      continue
                  }

            serviceDefinition.realizeService()
        }
    }

    /// Starts the registry.
    /// The call MUST be done explicetly, so eager services can be constructed immediatly.
    public static func performStartup() {
        guard let registerFn = Registry.startRegistryOnce else {
            fatalError("🚨 ERROR: Registry was already started!")
        }

        registerFn()
    }

    public static func performShutdown() {
        guard Registry.isStarted else {
            fatalError("🚨 ERROR: Registry wasn't started yet!")
        }

        shutdownRegistry()
    }

    // MARK: - PROXY / RESOLVE

    private func proxy<S>(_ type: S.Type = S.self) -> Proxy<S> {
        pthread_mutex_lock(&Registry.resolveMutex)

        let fqsn = String(reflecting: type)
        guard let definitionAny = self.serviceDefinitions[fqsn] else {
            pthread_mutex_unlock(&Registry.resolveMutex)
            fatalError("🚨 ERROR: No registration for type '\(fqsn)' found")
        }

        guard let definition = definitionAny as? ServiceDefinition<S> else {
            // swiftlint:disable force_cast
            let baseDef = definitionAny as! ServiceBaseDefinition
            let proxyTypeName = String(reflecting: type)
            pthread_mutex_unlock(&Registry.resolveMutex)
            // swiftlint:disable line_length
            fatalError("🚨 ERROR: Registration type mismatch: defined='\(baseDef.typeName)' - expected/injected='\(proxyTypeName)'")
        }

        pthread_mutex_unlock(&Registry.resolveMutex)

        return definition.proxy()
    }

    internal static func proxy<S>(_ type: S.Type = S.self) -> Proxy<S> {
        guard Registry.isStarted else {
            fatalError("🚨 ERROR: Registry MUST be started first by calling performStartup()!")
        }

        return Registry.instance.proxy(type)
    }

    /// Immediatly resolves a service, regardles of its realization type.
    public static func resolve<S>(_ type: S.Type = S.self) -> S {
        let proxyFn = Registry.proxy(type)
        let service = proxyFn()
        return service
    }

    // MARK: - HELPER (PUBLIC)

    /// Prints all registered services.
    public static func printServices() {
        print("📖 REGISTERED SERVICES:")
        guard Registry.instance.serviceDefinitions.isEmpty == false else {
            print("   No services registered")
            return
        }

        let definitions = Registry.instance.serviceDefinitions.values
        // swiftlint:disable force_cast
            .map { $0 as! ServiceBaseDefinition }
            .sorted { $0.typeName < $1.typeName }

        let maxLength = definitions.map(\.typeName.count).max() ?? 0

        for definition in definitions {
            let serviceName = definition.typeName.padding(toLength: maxLength, withPad: " ", startingAt: 0)
            let status = definition.realizationStatus

            print("    \(serviceName) : \(status)")
        }
    }

    // MARK: - HELPER (PRIVATE)

    private func buildIdentitier<S>(_ type: S.Type) -> Int {
        ObjectIdentifier(type).hashValue
    }
}
