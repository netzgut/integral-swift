//
//  RegistryModule.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

public protocol RegistryModule {

    static func imports() -> [RegistryModule.Type]

    static func onStartup()
    static func onShutdown()

    @discardableResult
    static func register<S>(_ type: S.Type,
                            factory: @escaping Factory<S>) -> ServiceOptions

    @discardableResult
    static func override<S>(_ type: S.Type,
                            factory: @escaping Factory<S>) -> ServiceOptions

    @discardableResult
    static func lazy<S>(_ type: S.Type ,
                        factory: @escaping Factory<S>) -> ServiceOptions

    @discardableResult
    static func eager<S>(_ type: S.Type,
                         factory: @escaping Factory<S>) -> ServiceOptions
}

public extension RegistryModule {

    static func imports() -> [RegistryModule.Type] {
        return []
    }

    static func onStartup() {
        // NOOP
    }

    static func onShutdown() {
        // NOOP
    }

    @discardableResult
    static func register<S>(_ type: S.Type = S.self,
                            factory: @escaping Factory<S>) -> ServiceOptions {
        Registry.register(type,
                          factory: factory)
    }

    @discardableResult
    static func override<S>(_ type: S.Type = S.self,
                            factory: @escaping Factory<S>) -> ServiceOptions {
        Registry.override(type,
                          factory: factory)
    }

    @discardableResult
    static func lazy<S>(_ type: S.Type = S.self,
                        factory: @escaping Factory<S>) -> ServiceOptions {
        Registry.lazy(type,
                      factory: factory)
    }

    @discardableResult
    static func eager<S>(_ type: S.Type = S.self,
                         factory: @escaping Factory<S>) -> ServiceOptions {
        Registry.eager(type,
                       factory: factory)
    }
}