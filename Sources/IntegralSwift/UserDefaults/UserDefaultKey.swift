//
//  UserDefaultKey.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

public struct UserDefaultKey: RawRepresentable, Equatable, Hashable, Comparable {
    public typealias RawValue = String

    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: UserDefaultKey,
                          rhs: UserDefaultKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
