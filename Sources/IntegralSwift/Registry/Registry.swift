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

public typealias ServiceFactory<S> = () -> S

public protocol RegistryStartup {
    static func registryStartup()
}

public final class Registry {

    public static var standard = Registry()

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
                                   factory: @escaping ServiceFactory<S>) -> ServiceDefinition<S> {
        self.standard.register(type, factory: factory)
    }

    @discardableResult
    public static func override<S>(_ type: S.Type = S.self,
                                   factory: @escaping ServiceFactory<S>) -> ServiceDefinition<S> {
        self.standard.override(type, factory: factory)
    }

    private static var registrationMutex: pthread_mutex_t = {
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)
        return mutex
    }()

    private typealias ServicesRegsitrationFn = () -> Void

    private static var registerServices: ServicesRegsitrationFn? = Registry.registerServicesFn

    private static var registerServicesFn: ServicesRegsitrationFn = {
        pthread_mutex_lock(&Registry.registrationMutex)
        defer {
            pthread_mutex_unlock(&Registry.registrationMutex)
        }

        guard Registry.registerServices != nil,
              let registryStartup = (Registry.standard as Any) as? RegistryStartup else {
            return
        }

        type(of: registryStartup).registryStartup()

        Registry.registerServices = nil
    }

    private var resolveMutex = pthread_mutex_t()

    public init() {
        pthread_mutex_init(&self.resolveMutex, nil)
    }

    public final func proxy<S>(_ type: S.Type = S.self) -> ServiceProxy<S>? {
        pthread_mutex_lock(&self.resolveMutex)
        defer { pthread_mutex_unlock(&self.resolveMutex) }

        let identifier = buildIdentitier(type)
        guard let definition = self.serviceDefinitions[identifier] as? ServiceDefinition<S> else {
            return nil
        }

        return definition.proxy()
    }

    public static func proxy<S>(_ type: S.Type = S.self) -> ServiceProxy<S> {
        Registry.registerServices?()

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

}
