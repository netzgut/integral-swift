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

protocol ServiceBaseDefinition {
    var name: String { get }
    var isLazy: Bool { get }
    var isRealized: Bool { get }

    var status: String { get }
}

extension ServiceDefinition {

    var status: String {
        let lazy = self.isLazy ? " (lazy)" : ""
        let state =  self.isRealized ? "REALIZED" : "unrealized"
        return "\(self.name)\(lazy) : \(state)"
    }
}

public class ServiceDefinition<S>: ServiceBaseDefinition {

    var type: S.Type
    var name: String

    private var factory: ServiceFactory<S>
    internal var isLazy: Bool = false
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

    internal func proxy() -> ServiceProxy<S> {
        if let service = self.realizedService {
            return { service }
        }

        guard self.isLazy else {
            let service = self.factory()
            self.realizedService = service
            return { service }
        }

        let proxy: ServiceProxy<S> = {
            let service = self.factory()
            self.realizedService = service
            return service
        }

        return proxy
    }

    @discardableResult
    public final func lazy() -> ServiceDefinition<S> {
        self.isLazy = true
        return self
    }
}
