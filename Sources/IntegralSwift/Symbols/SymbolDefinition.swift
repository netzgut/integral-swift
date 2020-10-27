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

internal protocol SymbolDefinition {
    var key: SymbolKey { get }

    func resolve<T>() -> T
}

internal struct ConstantSymbol: SymbolDefinition {

    internal var key: SymbolKey
    internal var value: Any

    internal func resolve<T>() -> T {
        self.value as! T
    }
}

internal struct DynamicSymbol: SymbolDefinition {

    internal var key: SymbolKey
    internal var factory: SymbolFactory<Any>

    internal func resolve<T>() -> T {
        self.factory() as! T
    }
}

class LazySymbol: SymbolDefinition {

    internal var key: SymbolKey
    internal var value: Any?
    internal var factory: SymbolFactory<Any>

    internal init(key: SymbolKey,
         factory: @escaping SymbolFactory<Any>) {
        self.key = key
        self.factory = factory
    }

    internal func resolve<T>() -> T {
        if self.value == nil {
            self.value = self.factory()
        }

        return self.value as! T
    }
}
