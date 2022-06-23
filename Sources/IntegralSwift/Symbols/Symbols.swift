//
//  Symbols.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
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

    internal static let instance = Symbols()

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
                                   isDefault: Bool = false,
                                   _ value: T) {
        Symbols.constant(key.rawValue,
                         type,
                         isDefault,
                         value)
    }

    public static func constant<T>(_ key: String,
                                   _ type: T.Type = T.self,
                                   _ isDefault: Bool = false,
                                   _ value: T) {
        Symbols.instance.constant(key: key,
                                  type: type,
                                  isDefault: isDefault,
                                  value: value)
    }

    public static func constant<T>(_ key: SymbolKey,
                                   _ type: T.Type = T.self,
                                   isDefault: Bool = false,
                                   factory: @escaping Factory<T>) {

        Symbols.constant(key.rawValue,
                         type,
                         isDefault: isDefault,
                         factory: factory)
    }

    public static func constant<T>(_ key: String,
                                   _ type: T.Type = T.self,
                                   isDefault: Bool = false,
                                   factory: @escaping Factory<T>) {
        Symbols.instance.constant(key: key,
                                  type: type,
                                  isDefault: isDefault,
                                  value: factory())
    }

    private func constant<T>(key: String,
                             type: T.Type,
                             isDefault: Bool = false,
                             value: T) {

        let def = ConstantSymbol(key: key,
                                 type: type,
                                 isDefault: isDefault,
                                 value: value)
        add(def)
    }

    public static func dynamic<T>(_ key: SymbolKey,
                                  _ type: T.Type = T.self,
                                  isDefault: Bool = false,
                                  factory: @escaping Factory<T>) {
        Symbols.dynamic(key.rawValue,
                        type,
                        isDefault: isDefault,
                        factory: factory)
    }

    public static func dynamic<T>(_ key: String,
                                  _ type: T.Type = T.self,
                                  isDefault: Bool = false,
                                  factory: @escaping Factory<T>) {
        Symbols.instance.dynamic(key: key,
                                 type: type,
                                 isDefault: isDefault,
                                 factory: factory)
    }

    private func dynamic<T>(key: String,
                            type: T.Type,
                            isDefault: Bool = false,
                            factory: @escaping Factory<T>) {

        let def = DynamicSymbol(key: key,
                                type: type,
                                isDefault: isDefault,
                                factory: factory)
        add(def)
    }

    public static func lazy<T>(_ key: SymbolKey,
                               _ type: T.Type = T.self,
                               isDefault: Bool = false,
                               factory: @escaping Factory<T>) {

        Symbols.lazy(key.rawValue,
                     type,
                     isDefault: isDefault,
                     factory: factory)
    }

    public static func lazy<T>(_ key: String,
                               _ type: T.Type = T.self,
                               isDefault: Bool = false,
                               factory: @escaping Factory<T>) {

        Symbols.instance.lazy(key: key,
                              type: type,
                              isDefault: isDefault,
                              factory: factory)
    }

    private func lazy<T>(key: String,
                         type: T.Type,
                         isDefault: Bool = false,
                         factory: @escaping Factory<T>) {

        let def = LazySymbol(key: key,
                             type: type,
                             isDefault: isDefault,
                             factory: factory)

        add(def)
    }

    private func add(_ def: SymbolBaseDefinition) {
        if let alreadyRegistered = self.symbols[def.key] as? SymbolBaseDefinition {
            // There's already a symbol registered, following states trigger a fatalError:
            // - Both are defaults
            // - Both are non-default
            if alreadyRegistered.isDefault == def.isDefault {
                // swiftlint:disable line_length
                fatalError("🚨 ERROR: Symbol '\(alreadyRegistered.description)' is already registered'.")
            }

            // Default is registered AFTER a non-default was sow e ignore it
            if def.isDefault {
                return
            }
        }

        self.symbols[def.key] = def
    }

    private func proxy<T>(_ key: String,
                          _ type: T.Type = T.self) -> Proxy<T>? {
        pthread_mutex_lock(&self.resolveMutex)
        defer { pthread_mutex_unlock(&self.resolveMutex) }

        guard let definitionAny = self.symbols[key] else {
            fatalError("🚨 ERROR: Symbol '\(key)' not found")
        }

        guard let definition = definitionAny as? SymbolDefinition<T> else {
            // swiftlint:disable force_cast
            let baseDef = definitionAny as! SymbolBaseDefinition
            let actualTypeName = String(reflecting: type)
            // swiftlint:disable line_length
            fatalError("🚨 ERROR: Symbol '\(key)' type mismatch: required='\(baseDef.typeName)' - actual='\(actualTypeName)'")
        }

        return definition.proxy()
    }

    internal static func proxy<T>(_ key: String,
                                  _ type: T.Type = T.self) -> Proxy<T> {
        guard let proxy = Symbols.instance.proxy(key, type) else {
            fatalError("Symbol '\(key)' not found")
        }

        return proxy
    }

    public static func resolve<S>(_ key: SymbolKey,
                                  _ type: S.Type = S.self) -> S {
        resolve(key.rawValue, type)
    }

    public static func resolve<S>(_ key: String,
                                  _ type: S.Type = S.self) -> S {
        let proxyFn = Symbols.proxy(key, type)
        let symbol = proxyFn()
        return symbol
    }

    // MARK: - Test helper

    static func reset() {
        Symbols.instance.reset()
    }

    private func reset() {
        pthread_mutex_lock(&self.resolveMutex)
        defer { pthread_mutex_unlock(&self.resolveMutex) }
        self.symbols.removeAll()
    }
}
