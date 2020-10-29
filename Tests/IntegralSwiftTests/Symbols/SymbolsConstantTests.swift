import XCTest
@testable import IntegralSwift

final class SymbolsConstantTests: XCTestCase {

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
}
