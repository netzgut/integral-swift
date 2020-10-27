//
//  Symbol.swift
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
public struct Symbol<T> {

    private var proxy: SymbolProxy<T>
    private var valueOverride: T?

    public init(_ symbol: SymbolKey) {
        self.init(symbol.rawValue)
    }

    public init(_ symbol: String) {
        self.proxy = Symbols.proxy(T.self, symbol)
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
