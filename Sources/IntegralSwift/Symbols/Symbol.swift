//
//  Symbol.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

@propertyWrapper
public struct Symbol<T> {

    private var proxy: Proxy<T>
    private var valueOverride: T?

    public init(_ key: SymbolKey) {
        self.init(key.rawValue)
    }

    public init(_ key: String) {
        self.proxy = Symbols.proxy(key, T.self)
    }

    public var wrappedValue: T {
        get {
            if let value = self.valueOverride {
                return value
            }

            return self.proxy()
        }
        set {
            self.valueOverride = newValue
        }
    }
}
