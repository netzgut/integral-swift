//
//  SymbolsLazyTests.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2021 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>
//

import XCTest
@testable import IntegralSwift

final class SymbolsLazyTests: XCTestCase {

    struct TestData {

        static let symbolKey = SymbolKey("lazy-value")

        @Symbol(symbolKey)
        var lazyValue: Int
    }

    func testLazyResolvedOnlyOnce() {

        // ARRANGE
        let lazyValue: Int = 42
        var resolveCounter = 0

        Symbols.lazy(TestData.symbolKey, Int.self) {
            resolveCounter += 1
            return lazyValue
        }

        // Symbols.constant("lazy-value", 5)

        // ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(resolveCounter, 0)
        XCTAssertEqual(testData.lazyValue, lazyValue)
        XCTAssertEqual(resolveCounter, 1)
        XCTAssertEqual(testData.lazyValue, lazyValue)
        XCTAssertEqual(resolveCounter, 1)
    }
}
