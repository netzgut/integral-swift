import XCTest
@testable import IntegralSwift

extension Registry: RegistryStartup {

    public static func registryStartup() {

        register(TestService.self) {
            print("Resolving")
            return TestService()
        }.lazy()
    }
}

class TestService {
    func testValue() -> String {
        "test"
    }
}

final class RegsitryTests: XCTestCase {

    class TestData {

        @Inject
        var service: TestService

        func testValue() -> String {
            self.service.testValue()
        }
    }

    func testExample() {

        // ARRANGE / ACT
        let testData: TestData = TestData()

        print("Before resolving")

        // ASSERT
        XCTAssertEqual(testData.testValue(), "test")
        XCTAssertEqual(testData.testValue(), "test")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
