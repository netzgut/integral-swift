//
//  SymbolsDefaultTests.swift
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

final class SymbolsDefaultTests: XCTestCase {

    override func tearDown() {
        Symbols.reset()
    }

    struct TestData {

        static let symbolKey = SymbolKey("key")

        @Symbol(TestData.symbolKey)
        var constantValue: Int
    }

    func testDefaultOverrideSymbol() {

        // ARRANGE
        let constantValue: Int = 42

        Symbols.constant(TestData.symbolKey, isDefault: true, -constantValue)
        Symbols.constant(TestData.symbolKey, isDefault: false, constantValue)

        // ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(testData.constantValue, constantValue)
    }

    func testDefaultIgnoreDefaultSymbol() {

        // ARRANGE
        let constantValue: Int = 42

        Symbols.constant(TestData.symbolKey, isDefault: false, constantValue)
        Symbols.constant(TestData.symbolKey, isDefault: true, -constantValue)

        // ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(testData.constantValue, constantValue)
    }

    func testDefaultDoubleDefaultSymbol() {

        // ARRANGE/ACT/ASSERT

        expectFatalError {
            Symbols.constant(TestData.symbolKey, isDefault: true, 42)
            Symbols.constant(TestData.symbolKey, isDefault: true, 23)
        }
    }

    func testDefaultDoubleNonDefaultSymbol() {

        // ARRANGE/ACT/ASSERT

        expectFatalError {
            Symbols.constant(TestData.symbolKey, isDefault: false, 42)
            Symbols.constant(TestData.symbolKey, isDefault: false, 23)
        }
    }
}
