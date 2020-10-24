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

    private var symbol: String
    private var valueOverride: T?

    public init(_ symbol: SymbolKey) {
        self.init(symbol.rawValue)
    }

    public init(_ symbol: String) {
        self.symbol = symbol
    }

    public var wrappedValue: T {
        get {
            if let value = self.valueOverride {
                return value
            }

            guard let definition = Symbols.standard.symbols[self.symbol] else {
                fatalError("Symbol Defintiion for '\(self.symbol)' is not found!")
            }

            return definition.resolve()
        }
        set {
            self.valueOverride = newValue
        }
    }
}
