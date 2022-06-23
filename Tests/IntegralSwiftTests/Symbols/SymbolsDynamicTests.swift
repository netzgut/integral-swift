//
//  SymbolsDynamicTests.swift
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

final class SymbolsDynamicTests: XCTestCase {

    override func tearDown() {
        Symbols.reset()
    }

    struct TestData {

        static let symbolKey = SymbolKey("dynamic")

        @Symbol(TestData.symbolKey)
        var dynamicValue: String
    }

    func testDynamicSymbol() {

        // ARRANGE
        Symbols.dynamic(TestData.symbolKey) {
            UUID().uuidString
        }

        // ACT
        let testData = TestData()
        let first = testData.dynamicValue
        let second = testData.dynamicValue

        // ASSERT
        XCTAssertNotEqual(first, second)
    }
}
