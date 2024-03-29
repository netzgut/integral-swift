//
//  SymbolsConstantTests.swift
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

final class SymbolsConstantTests: XCTestCase {

    override func tearDown() {
        Symbols.reset()
    }

    struct TestData {

        static let symbolKey = SymbolKey("constant-key")

        @Symbol(TestData.symbolKey)
        var constantValue: Int
    }

    func testConstantSymbol() {

        // ARRANGE
        let constantValue: Int = 42

        Symbols.constant(TestData.symbolKey, constantValue)

        // ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(testData.constantValue, constantValue)
    }

    func testConstantFactoryResolvedImmediatly() {

        // ARRANGE
        let constantValue: Int = 42
        var resolved = false
        Symbols.constant(TestData.symbolKey, Int.self) {
            resolved = true
            return constantValue
        }

        // ACT
        let testData = TestData()

        // ASSERT
        XCTAssertTrue(resolved)
        XCTAssertEqual(testData.constantValue, constantValue)
    }

    func testConstantResolve() {

        // ARRANGE
        let constantValue: Int = 42
        Symbols.constant(TestData.symbolKey, Int.self) {
            constantValue
        }

        // ACT
        let value: Int = Symbols.resolve(TestData.symbolKey)

        // ASSERT
        XCTAssertEqual(value, constantValue)
    }
}
