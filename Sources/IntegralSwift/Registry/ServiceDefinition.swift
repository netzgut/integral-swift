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

typealias ServiceProxy<S> = () -> S

public enum ServiceRealizationType {
    case injection
    case lazy
    case eager
}

protocol ServiceBaseDefinition {
    var name: String { get }
    var realizationType: ServiceRealizationType { get }
    var isRealized: Bool { get }

    var status: String { get }

    func realize()

}

extension ServiceDefinition {

    var status: String {
        let state =  self.isRealized ? "REALIZED" : "unrealized"
        return "\(self.name) (\(self.realizationType)) : \(state)"
    }
}

public class ServiceDefinition<S>: ServiceBaseDefinition {

    var type: S.Type
    var name: String

    private var factory: ServiceFactory<S>
    internal var realizationType: ServiceRealizationType = .injection
    private var realizedService: S?

    var isRealized: Bool {
        self.realizedService != nil
    }

    public init(type: S.Type = S.self,
                factory: @escaping ServiceFactory<S>) {
        self.type = type
        self.name = String(reflecting: type)
        self.factory = factory
    }

    @discardableResult
    internal func proxy() -> ServiceProxy<S> {
        if let service = self.realizedService {
            return { service }
        }

        guard self.realizationType == .lazy else {
            realize()
            return { self.realizedService! }
        }

        let proxy: ServiceProxy<S> = {
            self.realize()
            return self.realizedService!
        }

        return proxy
    }

    internal func realize() {
        let service = self.factory()
        self.realizedService = service
    }

    @discardableResult
    public final func lazy() -> ServiceDefinition<S> {
        self.realizationType = .lazy
        return self
    }

    @discardableResult
    public final func eager() -> ServiceDefinition<S> {
        self.realizationType = .eager
        return self
    }

    @discardableResult
    public final func realize(_ type: ServiceRealizationType) -> ServiceDefinition<S> {
        self.realizationType = type
        return self
    }

}
