//
//  UserDefault.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the erms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

@propertyWrapper
public struct UserDefault<T: UserDefaultsCompatible> {

    private var key: String
    private var defaultValue: T
    private var synchronize: Bool

    public init(_ key: UserDefaultKey,
                defaultValue: T,
                synchronize: Bool = true) {
        self.init(key.rawValue,
                  defaultValue: defaultValue,
                  synchronize: synchronize)
    }

    public init(_ key: String,
                defaultValue: T,
                synchronize: Bool = true) {

        self.key = key
        self.defaultValue = defaultValue
        self.synchronize = synchronize
    }

    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: self.key) as? T ?? self.defaultValue
        }
        set {
            UserDefaults.standard.setValue(newValue,
                                           forKey: self.key)

            if self.synchronize {
                UserDefaults.standard.synchronize()
            }
        }
    }
}
