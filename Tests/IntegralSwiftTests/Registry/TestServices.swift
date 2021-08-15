//
//  TestService.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2020 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import Foundation
@testable import IntegralSwift

protocol SharedTestService {

    static var isResolved: Bool { get set }

    func test() -> Bool

    var unique: UUID { get }

    static func reset()
}

extension SharedTestService {

    func test() -> Bool {
        true
    }

    static func reset() {
        Self.isResolved = false
    }
}

protocol InjectTestService: SharedTestService { }

class TestServiceImpl: InjectTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        TestServiceImpl.isResolved = true
    }
}

protocol LazyTestService: SharedTestService { }
protocol LazyAfterRegisterTestService: SharedTestService { }

class LazyTestServiceImpl: LazyTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

     init() {
        LazyTestServiceImpl.isResolved = true
    }
}

class LazyAfterRegisterTestServiceImpl: LazyAfterRegisterTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

     init() {
        LazyAfterRegisterTestServiceImpl.isResolved = true
    }
}

protocol EagerTestService: SharedTestService { }
protocol EagerAfterRegisterTestService: SharedTestService { }

class EagerTestServiceImpl: EagerTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

     init() {
        EagerTestServiceImpl.isResolved = true
    }
}

class EagerAfterRegisterTestServiceImpl: EagerAfterRegisterTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        EagerAfterRegisterTestServiceImpl.isResolved = true
    }
}
