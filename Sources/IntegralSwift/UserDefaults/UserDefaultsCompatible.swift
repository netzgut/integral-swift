//
//  UserDefaultsCompatible.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

public protocol UserDefaultsCompatible {}

extension Data: UserDefaultsCompatible {}
extension String: UserDefaultsCompatible {}
extension Int: UserDefaultsCompatible {}
extension Double: UserDefaultsCompatible {}
extension Float: UserDefaultsCompatible {}
extension Bool: UserDefaultsCompatible {}
extension Date: UserDefaultsCompatible {}
extension Array: UserDefaultsCompatible {}
extension Dictionary: UserDefaultsCompatible where Key: UserDefaultsCompatible, Value: UserDefaultsCompatible {}
