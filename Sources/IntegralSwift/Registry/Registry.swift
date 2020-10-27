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

/// How to build a service, used in registrations
public typealias ServiceFactory<S> = () -> S

/// Entry-point for the IoC.
/// All registration should be done in an extension of this protocol.
public protocol RegistryRegistrations {
    static func registrations()
}

public final class Registry {

    private static var standard = Registry()

    private let registrationQueue = DispatchQueue(label: "integral-registry.registrationQueue",
                                                  attributes: .concurrent)
    private var _serviceDefinitions = [Int: Any]()
    private var serviceDefinitions: [Int: Any] {
        get {
            self.registrationQueue.sync { self._serviceDefinitions }
        }
        set {
            self.registrationQueue.async(flags: .barrier) {
                self._serviceDefinitions = newValue
            }
        }
    }

    private var resolveMutex = pthread_mutex_t()

    var printServicesOnStartup: Bool = true

    public init() {
        pthread_mutex_init(&self.resolveMutex, nil)
    }

    private func register<S>(_ type: S.Type = S.self,
                             factory: @escaping ServiceFactory<S>) -> ServiceDefinition<S> {

        let identifier = buildIdentitier(type)

        if let alreadyRegistered = self.serviceDefinitions[identifier] as? ServiceDefinition<S> {
            let name = String(reflecting: type)
            print("⚠️ WARNING: Service '\(alreadyRegistered.name)' is already registered and will be overriden by '\(name)'. Use 'Registry.override(...)' to silence this warning.")
        }

        let definition = ServiceDefinition(type: type,
                                           factory: factory)

        self.serviceDefinitions[identifier] = definition

        return definition
    }

    private func override<S>(_ type: S.Type = S.self,
                             factory: @escaping ServiceFactory<S>) -> ServiceDefinition<S> {

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

    @discardableResult
    public static func register<S>(_ type: S.Type = S.self,
                                   factory: @escaping ServiceFactory<S>) -> ServiceOptions {
        self.standard.register(type, factory: factory)
    }

    @discardableResult
    public static func override<S>(_ type: S.Type = S.self,
                                   factory: @escaping ServiceFactory<S>) -> ServiceOptions {
        self.standard.override(type, factory: factory)
    }

    private static var registrationMutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()

    private typealias ServicesRegsitrationFn = () -> Void

    private static var registerServicesOnce: ServicesRegsitrationFn? = Registry.registerServices

    private static func registerServices() {
        pthread_mutex_lock(&Registry.registrationMutex)
        defer {
            pthread_mutex_unlock(&Registry.registrationMutex)
        }

        // Make sure we haven't run registry startup yet
        guard Registry.registerServicesOnce != nil,
              let registrations = (Registry.standard as Any) as? RegistryRegistrations else {
            return
        }

        // Startup registry
        type(of: registrations).registrations()

        // Eager Load services
        for rawDefinition in Registry.standard.serviceDefinitions.values {
            guard let serviceOptions = rawDefinition as? ServiceOptions,
                  serviceOptions.realizationType == .eager,
                  let serviceDefinition = rawDefinition as? ServiceBaseDefinition else {
                break
            }

            serviceDefinition.realizeService()
        }

        Registry.registerServicesOnce = nil

        if Registry.standard.printServicesOnStartup {
            printServices()
        }
    }

    public static func performStartup() {
        guard let registerFn = Registry.registerServicesOnce else {
            fatalError("Registry was already started!")
        }

        registerFn()
    }

    private func proxy<S>(_ type: S.Type = S.self) -> ServiceProxy<S>? {
        pthread_mutex_lock(&self.resolveMutex)
        defer { pthread_mutex_unlock(&self.resolveMutex) }

        let identifier = buildIdentitier(type)
        guard let definition = self.serviceDefinitions[identifier] as? ServiceDefinition<S> else {
            return nil
        }

        return definition.proxy()
    }

    internal static func proxy<S>(_ type: S.Type = S.self) -> ServiceProxy<S> {
        guard self.registerServicesOnce == nil else {
            fatalError("Registry MUST be started manually!")
        }

        guard let proxy = Registry.standard.proxy(type) else {
            fatalError("No registration for type \(type) found")
        }

        return proxy
    }

    public static func resolve<S>(_ type: S.Type = S.self) -> S {
        let proxyFn = Registry.proxy(type)
        let service = proxyFn()
        return service
    }

    private func buildIdentitier<S>(_ type: S.Type) -> Int {
        ObjectIdentifier(type).hashValue
    }

    public static func printServices() {
        print("📖 REGISTERED SERVICES:")
        guard Registry.standard.serviceDefinitions.isEmpty == false else {
            print("   No services registered")
            return
        }

        let definitions = Registry.standard.serviceDefinitions.values
            .map { $0 as! ServiceBaseDefinition}
            .sorted{ $0.name < $1.name }

        let maxLength = definitions.map { $0.name.count}.max() ?? 0

        for definition in definitions {
            let serviceName = definition.name.padding(toLength: maxLength, withPad: " ", startingAt: 0)
            let status = definition.realizationStatus

            print("    \(serviceName) : \(status)")
        }
    }
}
