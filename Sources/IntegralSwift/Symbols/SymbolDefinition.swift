//
//  SymbolDefinition.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

internal protocol SymbolBaseDefinition: CustomStringConvertible {
    var key: String { get }
    var typeName: String { get }
    var isDefault: Bool { get }
    var symbolType: String { get }
}

internal class SymbolDefinition<T>: SymbolBaseDefinition {

    internal var key: String
    internal var typeName: String
    internal var type: T.Type
    internal var isDefault: Bool
    internal var factory: Factory<T>

    internal init(key: String,
                  type: T.Type,
                  isDefault: Bool,
                  factory: @escaping Factory<T>) {
        self.key = key
        self.typeName = String(reflecting: type)
        self.type = type
        self.isDefault = isDefault
        self.factory = factory
    }

    internal func proxy() -> Proxy<T> {
        fatalError("Must be overriden")
    }

    var symbolType: String {
        fatalError("Must be overriden")
    }

    var description: String {
        let description = "\(self.key) -> \(self.typeName) (\(self.symbolType))"
        guard self.isDefault else {
            return description
        }

        return "\(description) [default]"
    }
}

internal class ConstantSymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "constant"
    }

    internal var value: T

    internal init(key: String,
                  type: T.Type,
                  isDefault: Bool,
                  value: T) {
        self.value = value

        super.init(key: key,
                   type: type,
                   isDefault: isDefault,
                   factory: { value })
    }

    override internal func proxy() -> Proxy<T> {
        { self.value }
    }
}

internal class DynamicSymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "dynamic"
    }

    override internal func proxy() -> Proxy<T> {
        { self.factory() }
    }
}

class LazySymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "lazy"
    }

    internal var value: T?

    override internal func proxy() -> Proxy<T> {
        let proxy: Proxy<T> = {
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
