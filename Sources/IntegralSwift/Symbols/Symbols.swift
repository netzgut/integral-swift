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

    private let symbolsQueue = DispatchQueue(label: "integral-symbols.queue",
                                             attributes: .concurrent)
    private var _symbols = [String: SymbolDefinition]()

    public static let standard = Symbols()

    var symbols: [String: SymbolDefinition] {
        get {
            self.symbolsQueue.sync { self._symbols }
        }
        set {
            self.symbolsQueue.async(flags: .barrier) {
                self._symbols = newValue
            }
        }
    }

    public static func add<T: Any>(_ key: SymbolKey,
                                   type: T.Type = T.self,
                                   _ value: T) {

        Symbols.standard.add(key,
                             type: type,
                             value)
    }

    public func add<T: Any>(_ key: SymbolKey,
                            type: T.Type = T.self,
                            _ value: T) {

        let def = ConstantSymbol(key: key,
                                 value: value)

        self.symbols[key.rawValue] = def
    }

    public static func add<T: Any>(_ key: SymbolKey,
                                   type: T.Type = T.self,
                                   factory: @escaping SymbolFactory<T>) {

        Symbols.standard.add(key,
                             type: type,
                             factory: factory)
    }

    public func add<T: Any>(_ key: SymbolKey,
                            type: T.Type = T.self,
                            factory: @escaping SymbolFactory<T>) {

        let def = ConstantSymbol(key: key,
                                 value: factory())

        self.symbols[key.rawValue] = def
    }

    public static func dynamic<T: Any>(_ key: SymbolKey,
                                       type: T.Type = T.self,
                                       factory: @escaping SymbolFactory<T>) {
        Symbols.standard.dynamic(key,
                                 type: type,
                                 factory: factory)
    }

    public func dynamic<T: Any>(_ key: SymbolKey,
                                type: T.Type = T.self,
                                factory: @escaping SymbolFactory<T>) {

        let def = DynamicSymbol(key: key,
                                factory: factory)

        self.symbols[key.rawValue] = def
    }

    public static func lazy<T: Any>(_ key: SymbolKey,
                                    type: T.Type = T.self,
                                    factory: @escaping SymbolFactory<T>) {

        Symbols.standard.lazy(key,
                              type: type,
                              factory: factory)
    }

    public func lazy<T: Any>(_ key: SymbolKey,
                             type: T.Type = T.self,
                             factory: @escaping SymbolFactory<T>) {

        let def = LazySymbol(key: key,
                             factory: factory)

        self.symbols[key.rawValue] = def
    }
}
