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

public final class Symbols {

    internal static let standard = Symbols()

    private let symbolsQueue = DispatchQueue(label: "integral-symbols.queue",
                                             attributes: .concurrent)
    private var _symbols = [String: Any]()
    var symbols: [String: Any] {
        get {
            self.symbolsQueue.sync { self._symbols }
        }
        set {
            self.symbolsQueue.async(flags: .barrier) {
                self._symbols = newValue
            }
        }
    }

    private var resolveMutex = pthread_mutex_t()

    public init() {
        pthread_mutex_init(&self.resolveMutex, nil)
    }

    public static func constant<T>(_ key: SymbolKey,
                                   type: T.Type = T.self,
                                   _ value: T) {
        Symbols.constant(key.rawValue,
                         type,
                         value)
    }

    public static func constant<T>(_ key: String,
                                   _ type: T.Type = T.self,
                                   _ value: T) {
        Symbols.standard.constant(key: key,
                                  type: type,
                                  value: value)
    }

    public static func constant<T>(_ key: SymbolKey,
                                   _ type: T.Type = T.self,
                                   factory: @escaping Factory<T>) {

        Symbols.constant(key.rawValue,
                         type,
                         factory: factory)
    }

    public static func constant<T>(_ key: String,
                                   _ type: T.Type = T.self,
                                   factory: @escaping Factory<T>) {
        Symbols.standard.constant(key: key,
                                  type: type,
                                  value: factory())
    }

    private func constant<T>(key: String,
                             type: T.Type,
                             value: T) {

        let def = ConstantSymbol(key: key,
                                 type: type,
                                 value: value)
        add(def)
    }

    public static func dynamic<T>(_ key: SymbolKey,
                                  _ type: T.Type = T.self,
                                  factory: @escaping Factory<T>) {
        Symbols.dynamic(key.rawValue,
                        type,
                        factory: factory)
    }

    public static func dynamic<T>(_ key: String,
                                  _ type: T.Type = T.self,
                                  factory: @escaping Factory<T>) {
        Symbols.standard.dynamic(key: key,
                                 type: type,
                                 factory: factory)
    }

    private func dynamic<T>(key: String,
                            type: T.Type,
                            factory: @escaping Factory<T>) {

        let def = DynamicSymbol(key: key,
                                type: type,
                                factory: factory)
        add(def)
    }

    public static func lazy<T>(_ key: SymbolKey,
                               _ type: T.Type = T.self,
                               factory: @escaping Factory<T>) {

        Symbols.lazy(key.rawValue,
                     type,
                     factory: factory)
    }

    public static func lazy<T>(_ key: String,
                               _ type: T.Type = T.self,
                               factory: @escaping Factory<T>) {

        Symbols.standard.lazy(key: key,
                              type: type,
                              factory: factory)
    }

    private func lazy<T>(key: String,
                         type: T.Type,
                         factory: @escaping Factory<T>) {

        let def = LazySymbol(key: key,
                             type: type,
                             factory: factory)

        add(def)
    }

    private func add(_ def: SymbolBaseDefinition) {
        if let alreadyRegistered = self.symbols[def.key] as? SymbolBaseDefinition {
            print("⚠️ WARNING: Symbol '\(alreadyRegistered.description)' is already registered and will be overriden by '\(def.description)'.")
        }

        self.symbols[def.key] = def
    }

    private func proxy<T>(_ key: String,
                          _ type: T.Type = T.self) -> Proxy<T>? {
        pthread_mutex_lock(&self.resolveMutex)
        defer { pthread_mutex_unlock(&self.resolveMutex) }

        guard let definitionAny = self.symbols[key]  else {
            fatalError("🚨 ERROR: Symbol '\(key)' not found")
        }

        guard let definition = definitionAny as? SymbolDefinition<T> else {
            let baseDef = definitionAny as! SymbolBaseDefinition
            let actualTypeName = String(reflecting: type)
            fatalError("🚨 ERROR: Symbol type mismatch: required='\(baseDef.typeName)' - actual='\(actualTypeName)'")
        }

        return definition.proxy()
    }

    internal static func proxy<T>(_ key: String,
                                  _ type: T.Type = T.self) -> Proxy<T> {
        guard let proxy = Symbols.standard.proxy(key, type) else {
            fatalError("Symbol '\(key)' not found")
        }

        return proxy
    }
}
