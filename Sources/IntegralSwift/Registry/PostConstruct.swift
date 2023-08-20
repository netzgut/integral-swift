//
//  PostConstruct.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2021 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation

/// PostConstruct marker interface.
///
/// A service conforming to PostConstruct will execute the `postConstruct` function
/// after the service is constructed.
public protocol PostConstruct {

    func postConstruct()
}
