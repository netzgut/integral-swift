import XCTest
@testable import IntegralSwift

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

        @UserDefault(.testKey, defaultValue: TestData.defaultValue)
        var value: String
    }

    func testExample() {

        // ARRANGE / ACT
        let testData = TestData()

        // ASSERT
        XCTAssertEqual(testData.value, TestData.defaultValue)
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
