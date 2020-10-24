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

protocol SymbolDefinition {
    var key: SymbolKey { get }

    func resolve<T>() -> T
}

struct ConstantSymbol: SymbolDefinition {

    var key: SymbolKey
    var value: Any

    func resolve<T>() -> T {
        self.value as! T
    }
}

struct DynamicSymbol: SymbolDefinition {
    var key: SymbolKey
    var factory: SymbolFactory<Any>

    func resolve<T>() -> T {
        self.factory() as! T
    }
}

class LazySymbol: SymbolDefinition {
    var key: SymbolKey
    var value: Any?
    var factory: SymbolFactory<Any>

    init(key: SymbolKey,
         factory: @escaping SymbolFactory<Any>) {
        self.key = key
        self.factory = factory
    }

    func resolve<T>() -> T {
        if self.value == nil {
            self.value = self.factory()
        }

        return self.value as! T
    }
}
