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

    internal var realizationType: ServiceRealizationType = Registry.defaultServiceRealizationType

    /// Marks a service as "lazy", so it's realized at first access, not at injection.
    @discardableResult
    public final func lazy() -> ServiceOptions {
        self.realizationType = .lazy
        return self
    }

    /// Marks a service as "eager", so it's realized at Registry startup (e.g. background helper).
    @discardableResult
    public final func eager() -> ServiceOptions {
        self.realizationType = .eager
        return self
    }

    /// Changes the ServiceRealizationType of a service.
    @discardableResult
    public final func realize(_ type: ServiceRealizationType) -> ServiceOptions {
        self.realizationType = type
        return self
    }
}

internal protocol ServiceBaseDefinition {

    /// Service name, derived from type
    var typeName: String { get }

    /// Has the service been realized yet?
    var isRealized: Bool { get }

    /// Current state of realization, for debugging purposes
    var realizationStatus: String { get }

    /// Force the service to be realized
    func realizeService()

    /// Is the proxy/it's owning registry still active?
    var isActive: Bool { get set }
}

internal extension ServiceDefinition {

    var realizationStatus: String {
        let state =  self.isRealized ? "REALIZED" : "DEFINED "
        return "\(state) (\(self.realizationType))"
    }
}

/// Definition of a Service.
/// Knows everything to realize/build a service by providing a proxy
internal class ServiceDefinition<S>: ServiceOptions, ServiceBaseDefinition {

    internal var typeName: String

    private var type: S.Type
    private var factory: Factory<S>
    private var realizedService: S?

    internal var isActive: Bool = true

    internal var isRealized: Bool {
        self.realizedService != nil
    }

    internal init(type: S.Type = S.self,
                  factory: @escaping Factory<S>) {
        self.typeName = String(reflecting: type)
        self.type = type
        self.factory = factory
    }

    internal func proxy() -> Proxy<S> {
        guard self.isActive else {
            fatalError("🚨 ERROR: Registry was shutdown, Proxy can't be created.")
        }

        if let service = self.realizedService {
            return { service }
        }

        guard self.realizationType == .lazy else {
            realizeService()
            return { self.realizedService! }
        }

        let proxy: Proxy<S> = {
            self.realizeService()
            return self.realizedService!
        }

        return proxy
    }

    internal func realizeService() {
        guard self.isActive else {
            fatalError("🚨 ERROR: Registry was shutdown, Proxy can't be realized.")
        }

        let service = self.factory()
        self.realizedService = service
    }
}
