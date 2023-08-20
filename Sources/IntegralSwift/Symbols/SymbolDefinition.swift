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

protocol SymbolBaseDefinition: CustomStringConvertible {
    var key: String { get }
    var typeName: String { get }
    var isDefault: Bool { get }
    var symbolType: String { get }
}

class SymbolDefinition<T>: SymbolBaseDefinition {

    var key: String
    var typeName: String
    var type: T.Type
    var isDefault: Bool
    var factory: Factory<T>

    init(key: String,
         type: T.Type,
         isDefault: Bool,
         factory: @escaping Factory<T>) {
        self.key = key
        self.typeName = String(reflecting: type)
        self.type = type
        self.isDefault = isDefault
        self.factory = factory
    }

    func proxy() -> Proxy<T> {
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

class ConstantSymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "constant"
    }

    var value: T

    init(key: String,
         type: T.Type,
         isDefault: Bool,
         value: T) {
        self.value = value

        super.init(key: key,
                   type: type,
                   isDefault: isDefault,
                   factory: { value })
    }

    override func proxy() -> Proxy<T> {
        { self.value }
    }
}

class DynamicSymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "dynamic"
    }

    override func proxy() -> Proxy<T> {
        { self.factory() }
    }
}

class LazySymbol<T>: SymbolDefinition<T> {

    override var symbolType: String {
        "lazy"
    }

    var value: T?

    override func proxy() -> Proxy<T> {
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
