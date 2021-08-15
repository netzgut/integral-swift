//
//  OptionalUserDefault.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

@propertyWrapper
public struct OptionalUserDefault<T: UserDefaultsCompatible> {

    private var key: String
    private var synchronize: Bool

    public init(_ key: UserDefaultKey,
                synchronize: Bool = true) {
        self.init(key.rawValue,
                  synchronize: synchronize)
    }

    public init(_ key: String,
                synchronize: Bool = true) {

        self.key = key
        self.synchronize = synchronize
    }

    public var wrappedValue: T? {
        get {
            UserDefaults.standard.object(forKey: self.key) as? T
        }
        set {

            if let actualValue = newValue {
                UserDefaults.standard.setValue(actualValue,
                                               forKey: self.key)
            } else {
                UserDefaults.standard.removeObject(forKey: self.key)
            }

            if self.synchronize {
                UserDefaults.standard.synchronize()
            }
        }
    }
}
