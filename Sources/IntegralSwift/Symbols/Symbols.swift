//
//  Symbols.swift
//  
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the erms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

/// Helper struct to easly add constant keys, like Notification.Name
public struct SymbolKey: RawRepresentable, Equatable, Hashable, Comparable {
    public typealias RawValue = String

    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: SymbolKey,
                          rhs: SymbolKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

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

/*
 class SymbolDefinition {
 
 var key: SymbolKey
 var resolvedValue: Any!
 var isLazy: Bool
 var isDynamic: Bool
 var factory: SymbolFactory<Any>
 
 init(key: SymbolKey,
 isLazy: Bool,
 isDynamic: Bool,
 factory: @escaping SymbolFactory<Any>) {
 
 self.key = key
 self.isLazy = isLazy
 self.isDynamic = isDynamic
 self.factory = factory
 
 if self.isLazy == false {
 self.resolvedValue = factory()
 }
 }
 
 init(key: SymbolKey,
 value: Any) {
 
 self.key = key
 self.isLazy = false
 self.isDynamic = false
 self.factory = { value }
 
 if self.isLazy == false {
 self.resolvedValue = factory()
 }
 }
 
 func resolve<T>() -> T {
 if resolvedValue == nil || self.isDynamic {
 self.resolvedValue = self.factory()
 }
 
 return self.resolvedValue as! T
 }
 }
 */

public final class Symbols {

    static var symbols = [String: SymbolDefinition]()

    public static func add<T: Any>(_ key: SymbolKey,
                                   type: T.Type = T.self,
                                   _ value: T) {

        let def = ConstantSymbol(key: key,
                                 value: value)

        self.symbols[key.rawValue] = def
    }

    public static func add<T: Any>(_ key: SymbolKey,
                                   type: T.Type = T.self,
                                   factory: @escaping SymbolFactory<T>) {

        let def = ConstantSymbol(key: key,
                                 value: factory())

        self.symbols[key.rawValue] = def
    }

    public static func dynamic<T: Any>(_ key: SymbolKey,
                                       type: T.Type = T.self,
                                       factory: @escaping SymbolFactory<T>) {

        let def = DynamicSymbol(key: key,
                                factory: factory)

        self.symbols[key.rawValue] = def
    }

    public static func lazy<T: Any>(_ key: SymbolKey,
                                    type: T.Type = T.self,
                                    factory: @escaping SymbolFactory<T>) {

        let def = LazySymbol(key: key,
                             factory: factory)

        self.symbols[key.rawValue] = def
    }

}

@propertyWrapper
public struct Symbol<T> {

    private var symbol: String

    public init(_ symbol: SymbolKey) {
        self.init(symbol.rawValue)
    }

    public init(_ symbol: String) {

        self.symbol = symbol
    }

    public var wrappedValue: T {
        get {
            guard let def = Symbols.symbols[self.symbol] else {
                fatalError("Symbol Defintiion for '\(self.symbol)' is not found!")
            }

            return def.resolve()
        }
        set {
            fatalError("Symbols can't be set via code! (\(self.symbol))")
        }
    }
}
