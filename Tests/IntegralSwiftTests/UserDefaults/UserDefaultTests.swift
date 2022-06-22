//
//  UserDefaultTests.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2021 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

@testable import IntegralSwift
import XCTest

extension UserDefaultKey {
    static let testKey = UserDefaultKey("test-key")
}

final class UserDefaultTests: XCTestCase {

    override class func tearDown() {
        super.tearDown()

        UserDefaults.standard.removeObject(forKey: UserDefaultKey.testKey.rawValue)
        UserDefaults.standard.synchronize()
    }

    struct TestData {

        static let defaultValue = "this is a default value"

        @UserDefault(.testKey, defaultValue: TestData.defaultValue, userDefaults: UserDefaults(suiteName: "t")!)
        var value: String
    }

    func testUserDefault() {

        // ARRANGE / ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(testData.value, TestData.defaultValue)
    }
}
