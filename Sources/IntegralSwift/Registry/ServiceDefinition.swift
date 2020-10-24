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

public typealias ServiceProxy<S> = () -> S

public class ServiceDefinition<S> {

    var identifier: Int

    private var factory: ServiceFactory<S>
    private var isLazy: Bool = false
    private var realizedService: S?

    public init(_ type: S.Type = S.self,
                identifier: Int,
                factory: @escaping ServiceFactory<S>) {
        self.identifier = identifier
        self.factory = factory
    }

    public final func proxy() -> ServiceProxy<S> {
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
