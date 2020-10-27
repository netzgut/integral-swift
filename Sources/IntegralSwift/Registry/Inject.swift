//
//  Inject.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the erms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

@propertyWrapper
public struct Inject<S> {

    private var proxy: ServiceProxy<S>
    private var service: S?

    public init() {
        self.proxy = Registry.proxy(S.self)
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
