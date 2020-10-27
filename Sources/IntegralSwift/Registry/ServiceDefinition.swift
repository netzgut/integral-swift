//
//  ServiceDefinition.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the erms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

/// The point in time which a Service is realized / build
public enum ServiceRealizationType {
    /// On injection by @Inject, without actually using the property.
    case injection

    /// On first "real" usage, e.g. accessing the property.
    case lazy

    // On registry startup. Used for background-like services.
    case eager
}

/// Options of a service definition. Only public way to interact with a registration.
public class ServiceOptions {

    internal var realizationType: ServiceRealizationType = .injection

    @discardableResult
    public final func lazy() -> ServiceOptions {
        self.realizationType = .lazy
        return self
    }

    @discardableResult
    public final func eager() -> ServiceOptions {
        self.realizationType = .eager
        return self
    }

    @discardableResult
    public final func realize(_ type: ServiceRealizationType) -> ServiceOptions {
        self.realizationType = type
        return self
    }
}


/// Shared protocol for easier casting/usage.
internal protocol ServiceBaseDefinition {

    /// Service name, derived from type
    var name: String { get }

    // Has the service been realized yet?
    var isRealized: Bool { get }

    // Current state of realization, for debugging purposes
    var realizationStatus: String { get }

    // Force the service to be realized
    func realizeService()
}

internal extension ServiceDefinition {

    var realizationStatus: String {
        let state =  self.isRealized ? "REALIZED" : "DEFINED "
        return "\(state) (\(self.realizationType))"
    }
}

/// Helper lambda for building a service
internal typealias ServiceProxy<S> = () -> S


/// Definition of a Service.
/// Knows everything to realize/build a service by providing a proxy
internal class ServiceDefinition<S>: ServiceOptions, ServiceBaseDefinition {

    internal var name: String

    private var type: S.Type
    private var factory: ServiceFactory<S>
    private var realizedService: S?

    internal var isRealized: Bool {
        self.realizedService != nil
    }

    internal init(type: S.Type = S.self,
                factory: @escaping ServiceFactory<S>) {
        self.name = String(reflecting: type)
        self.type = type
        self.factory = factory
    }

    @discardableResult
    internal func proxy() -> ServiceProxy<S> {
        if let service = self.realizedService {
            return { service }
        }

        guard self.realizationType == .lazy else {
            realizeService()
            return { self.realizedService! }
        }

        let proxy: ServiceProxy<S> = {
            self.realizeService()
            return self.realizedService!
        }

        return proxy
    }

    internal func realizeService() {
        let service = self.factory()
        self.realizedService = service
    }
}
