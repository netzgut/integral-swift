import XCTest
@testable import IntegralSwift

extension SymbolKey {
    static let bundle = SymbolKey("bundle")
    static let executable = SymbolKey("executable")
}

final class SymbolsTests: XCTestCase {

    struct TestData {

        @Symbol(.bundle)
        var value: String

        @Symbol(.executable)
        var executable: String?
    }

    func testExample() {

        // ARRANGE
        Symbols.lazy(.bundle) { Bundle.main.bundlePath }
        Symbols.add(.executable, Bundle.main.executablePath)

        // ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(testData.value, Bundle.main.bundlePath)
        XCTAssertEqual(testData.executable, Bundle.main.executablePath)
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
