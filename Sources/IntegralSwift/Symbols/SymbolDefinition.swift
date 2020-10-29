//
//  SymbolDefinition.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the erms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

public typealias SymbolFactory<T> = () -> T
public typealias SymbolProxy<T> = () -> T

internal protocol SymbolBaseDefinition: CustomStringConvertible {
    var key: String { get }
    var typeName: String { get }
    var symbolType: String { get }
}

internal class SymbolDefinition<T>: SymbolBaseDefinition {

    internal var key: String
    internal var typeName: String
    internal var type: T.Type
    internal var factory: SymbolFactory<T>

    internal init(key: String,
                  type: T.Type,
                  factory: @escaping SymbolFactory<T>) {
        self.key = key
        self.typeName = String(reflecting: type)
        self.type = type
        self.factory = factory
    }

    internal func proxy() -> SymbolProxy<T> {
        fatalError("Must be overriden")
    }

    var symbolType: String {
        fatalError("Must be overriden")
    }

    var description: String {
        "\(self.key) -> \(self.typeName) (\(self.symbolType))"
    }
}

internal class ConstantSymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "constant"
    }

    internal var value: T

    internal init(key: String,
                  type: T.Type,
                  value: T) {
        self.value = value

        super.init(key: key,
                   type: type,
                   factory: { value })
    }

    override internal func proxy() -> SymbolProxy<T> {
        { self.value }
    }
}

internal class DynamicSymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "dynamic"
    }

    override internal func proxy() -> SymbolProxy<T> {
        { self.factory() }
    }
}

class LazySymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "lazy"
    }

    internal var value: T?

    override internal func proxy() -> SymbolProxy<T> {
        let proxy: SymbolProxy<T> = {
            if let value = self.value {
                return value
            }

            let value = self.factory()
            self.value = value

            return value
        }
        return proxy
    }
}
