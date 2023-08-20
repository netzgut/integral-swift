//
//  Inject.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

/// Injection property wrapper.
///
/// Regardless of ServiceRealizationType (e.g. injection, lazy, eager) only one wrapper is used.
/// The underlying service definition is responsible for how a service is actually handled.
@propertyWrapper
public struct Inject<S> {

    private var proxy: Proxy<S>
    private var service: S?

    public init(_ serviceId: String? = nil) {
        self.proxy = Registry.proxy(type: S.self,
                                    serviceId: serviceId)
    }

    public var wrappedValue: S {
        mutating get {
            if let service = self.service {
                return service
            }
            let service = self.proxy()
            self.service = service
            return service
        }
        mutating set {
            self.service = newValue
        }
    }
}
