//
//  Registry.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the erms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

/// Entry-point for the Registry.
/// All registration should be done in an extension of this protocol.
public protocol RegistryRegistrations {
    static func onStartup()

    static func onShutdown()
}

public extension RegistryRegistrations {

    static func onShutdown() {
        // NOOP
    }
}

// The dependency injection container that contains all service definitions.
public final class Registry {

    // MARK: - SETTINGS

    /// Prints all registered services after registry has started
    public static var printServicesOnStartup: Bool = true

    // MARK: - PRIVATE PROPERTIES

    private static var standard = Registry()

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
        self.standard.register(type, factory: factory)
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
        self.standard.override(type, factory: factory)
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
        self.standard.register(type, factory: factory).lazy()
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
        self.standard.register(type, factory: factory).eager()
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

        if self.serviceDefinitions[identifier] != nil {
            let name = String(reflecting: type)
            print("⚠️ WARNING: No service registred for '\(name)'. Use 'Registry.register(...)' instead.")
        }

        let definition = ServiceDefinition(type: type,
                                           factory: factory)

        self.serviceDefinitions[identifier] = definition

        return definition
    }

    // MARK: - STARTUP

    private typealias ServicesRegsitrationFn = () -> Void

    private static var registerServicesOnce: ServicesRegsitrationFn? = Registry.registerServices

    private static func registerServices() {
        pthread_mutex_lock(&Registry.registrationMutex)

        // Make sure we haven't run registry startup yet
        guard Registry.registerServicesOnce != nil,
              let registrations = (Registry.standard as Any) as? RegistryRegistrations else {
            pthread_mutex_unlock(&Registry.registrationMutex)
            return
        }

        // Startup registry
        type(of: registrations).onStartup()

        // We need to set it nil before actually registering the services,
        // eager loading might crash due to not finished regist
        Registry.registerServicesOnce = nil

        pthread_mutex_unlock(&Registry.registrationMutex)

        eagerLoadServices()

        if Registry.printServicesOnStartup {
            printServices()
        }
    }

    private static func shutdownRegistry() {
        pthread_mutex_lock(&Registry.registrationMutex)

        // Make sure we haven't run registry startup yet

        guard Registry.registerServicesOnce == nil,
              Registry.standard.serviceDefinitions.isEmpty == false else {
            pthread_mutex_unlock(&Registry.registrationMutex)
            return
        }

        for case var def as ServiceBaseDefinition in Registry.standard.serviceDefinitions {
            def.isActive = false
        }

        Registry.standard.serviceDefinitions = [Int: Any]()
        Registry.registerServicesOnce = Registry.registerServices

        pthread_mutex_unlock(&Registry.registrationMutex)
    }

    private static func eagerLoadServices() {
        // Eager Load services
        for rawDefinition in Registry.standard.serviceDefinitions.values {
            guard let serviceOptions = rawDefinition as? ServiceOptions,
                  serviceOptions.realizationType == .eager,
                  let serviceDefinition = rawDefinition as? ServiceBaseDefinition else {
                break
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
            let actualTypeName = String(reflecting: type)
            pthread_mutex_unlock(&Registry.resolveMutex)
            fatalError("🚨 ERROR: Registration type mismatch: required='\(baseDef.typeName)' - actual='\(actualTypeName)'")
        }

        pthread_mutex_unlock(&Registry.resolveMutex)

        return definition.proxy()
    }

    internal static func proxy<S>(_ type: S.Type = S.self) -> Proxy<S> {
        guard self.registerServicesOnce == nil else {
            fatalError("🚨 ERROR: Registry MUST be started manually!")
        }

        return Registry.standard.proxy(type)
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
        guard Registry.standard.serviceDefinitions.isEmpty == false else {
            print("   No services registered")
            return
        }

        let definitions = Registry.standard.serviceDefinitions.values
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
