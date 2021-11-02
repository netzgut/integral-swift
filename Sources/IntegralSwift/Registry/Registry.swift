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
    private var _serviceDefinitions = [Int: Any]()
    private var serviceDefinitions: [Int: Any] {
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

    private static var registeredModules = Set<String>()

    // MARK: - MUTEX

    private static var registrationMutex: pthread_mutex_t = {
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

        let identifier = buildIdentitier(type)

        if let alreadyRegistered = self.serviceDefinitions[identifier] as? ServiceBaseDefinition {
            let name = String(reflecting: type)
            print("⚠️ WARNING: Service '\(alreadyRegistered.typeName)' is already registered and will be overriden by '\(name)'. Use 'Registry.override(...)' to silence this warning.")
        }

        let definition = ServiceDefinition(type: type,
                                           factory: factory)

        self.serviceDefinitions[identifier] = definition

        return definition
    }

    private func override<S>(_ type: S.Type = S.self,
                             factory: @escaping Factory<S>) -> ServiceDefinition<S> {

        let identifier = buildIdentitier(type)

        if self.serviceDefinitions[identifier] == nil {
            let name = String(reflecting: type)
            print("⚠️ WARNING: No service registred for '\(name)'. Use 'Registry.register(...)' instead.")
        }

        let definition = ServiceDefinition(type: type,
                                           factory: factory)

        self.serviceDefinitions[identifier] = definition

        return definition
    }

    // MARK: - STARTUP

    private typealias ServicesRegistrationFn = () -> Void

    private static var registerServicesOnce: ServicesRegistrationFn? = Registry.registerServices

    private static func registerServices() {
        pthread_mutex_lock(&Registry.registrationMutex)

        // Make sure we haven't run registry startup yet
        guard Registry.registerServicesOnce != nil,
              let registrations = (Registry.instance as Any) as? RegistryModule else {
            pthread_mutex_unlock(&Registry.registrationMutex)
            return
        }

        register(modules: [type(of: registrations)])

        // We need to set it nil before actually registering the services,
        // eager loading might crash due to not finished regist
        Registry.registerServicesOnce = nil

        pthread_mutex_unlock(&Registry.registrationMutex)

        eagerLoadServices()

        if Registry.printServicesOnStartup {
            printServices()
        }
    }

    private static func register(modules: [RegistryModule.Type]) {
        for module in modules {

            let moduleName = String(reflecting: module)

            register(modules: module.imports())

            if self.registeredModules.contains(moduleName) {
                print("⚠️ WARNING: Module '\(moduleName)' is already imported.")
                continue
            }

            module.onStartup()
            self.registeredModules.insert(moduleName)
        }
    }

    private static func shutdownRegistry() {
        pthread_mutex_lock(&Registry.registrationMutex)

        // Make sure we haven't run registry startup yet

        guard Registry.registerServicesOnce == nil,
              Registry.instance.serviceDefinitions.isEmpty == false,
              let registrations = (Registry.instance as Any) as? RegistryModule else {
            pthread_mutex_unlock(&Registry.registrationMutex)
            return
        }

        shutdown(modules: [type(of: registrations)])

        for maybeDef in Registry.instance.serviceDefinitions {

            if var def = maybeDef.value as? ServiceBaseDefinition {
                def.isActive = false
            }
        }

        Registry.instance.serviceDefinitions = [Int: Any]()
        Registry.registeredModules = Set<String>()
        Registry.registerServicesOnce = Registry.registerServices

        pthread_mutex_unlock(&Registry.registrationMutex)
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
        guard let registerFn = Registry.registerServicesOnce else {
            fatalError("🚨 ERROR: Registry was already started!")
        }

        registerFn()
    }

    public static func performShutdown() {
        guard Registry.registerServicesOnce == nil else {
            fatalError("🚨 ERROR: Registry wasn't started yet!")
        }

        shutdownRegistry()
    }

    // MARK: - PROXY / RESOLVE

    private func proxy<S>(_ type: S.Type = S.self) -> Proxy<S> {
        pthread_mutex_lock(&Registry.resolveMutex)

        let identifier = buildIdentitier(type)
        guard let definitionAny = self.serviceDefinitions[identifier]  else {
            pthread_mutex_unlock(&Registry.resolveMutex)
            fatalError("🚨 ERROR: No registration for type \(type) found")
        }

        guard let definition = definitionAny as? ServiceDefinition<S> else {
            let baseDef = definitionAny as! ServiceBaseDefinition
            let proxyTypeName = String(reflecting: type)
            pthread_mutex_unlock(&Registry.resolveMutex)
            fatalError("🚨 ERROR: Registration type mismatch: defined='\(baseDef.typeName)' - expected/injected='\(proxyTypeName)'")
        }

        pthread_mutex_unlock(&Registry.resolveMutex)

        return definition.proxy()
    }

    internal static func proxy<S>(_ type: S.Type = S.self) -> Proxy<S> {
        guard self.registerServicesOnce == nil else {
            fatalError("🚨 ERROR: Registry MUST be started manually!")
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
            .map { $0 as! ServiceBaseDefinition}
            .sorted { $0.typeName < $1.typeName }

        let maxLength = definitions.map { $0.typeName.count}.max() ?? 0

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
