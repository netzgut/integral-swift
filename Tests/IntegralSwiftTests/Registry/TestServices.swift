//
//  TestServices.swift
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
        isResolved = false
    }
}

protocol InjectTestService: SharedTestService { }

class TestServiceImpl: InjectTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }
}

class TestService2Impl: TestServiceImpl { }

protocol LazyTestService: SharedTestService { }
protocol LazyAfterRegisterTestService: SharedTestService { }

class LazyTestServiceImpl: LazyTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }
}

class LazyAfterRegisterTestServiceImpl: LazyAfterRegisterTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }
}

protocol EagerTestService: SharedTestService { }
protocol EagerAfterRegisterTestService: SharedTestService { }

class EagerTestServiceImpl: EagerTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }
}

class EagerAfterRegisterTestServiceImpl: EagerAfterRegisterTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }
}

protocol PostConstructService: SharedTestService, PostConstruct {

    static var isPostConstructed: Bool { get set }
}

class PostConstructServiceImpl: PostConstructService {

    static var isResolved: Bool = false
    static var isPostConstructed: Bool = false

    var unique: UUID = UUID()
    var postConstructUnique: UUID!

    init() {
        Self.isResolved = true
    }

    func postConstruct() {
        Self.isPostConstructed = true
        self.postConstructUnique = UUID()
    }

    static func reset() {
        self.isResolved = false
        self.isPostConstructed = false
    }
}

protocol PostConstructEagerService: PostConstructService { }

class PostConstructEagerServiceImpl: PostConstructEagerService {

    static var isResolved: Bool = false
    static var isPostConstructed: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }

    func postConstruct() {
        Self.isPostConstructed = true
    }

    static func reset() {
        self.isResolved = false
        self.isPostConstructed = false
    }
}

class CustomServiceIdServiceImpl: SharedTestService {

    static var isResolved: Bool = false

    var unique: UUID = UUID()

    init() {
        Self.isResolved = true
    }
}

class Circular1 {
    @Inject
    var circular2: Circular2
}

class Circular2: PostConstruct {

    @Inject
    var circular1: Circular1

    func postConstruct() {
        _ = self.circular1.circular2
    }
}
