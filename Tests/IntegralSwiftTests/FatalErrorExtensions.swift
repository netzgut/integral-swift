//
//  FatalErrorExtensions.swift
//
//  https://github.com/netzgut/integral-swift
//
//  Copyright (c) 2022 Ben Weidig
//
//  This work is licensed under the terms of the MIT license.
//  For a copy, see LICENSE, or <https://opensource.org/licenses/MIT>

@testable import IntegralSwift
// See: https://stackoverflow.com/a/68496755
import XCTest

extension XCTestCase {

    func expectFatalError(expectedMessage: String? = nil,
                          testcase: @escaping () -> Void) {

        // ARRANGE
        let expectation = self.expectation(description: "expectingFatalError")
        var assertionMessage: String?

        // OVERRIDE FATALERROR
        // This will terminate thread when fatalError is called.
        FatalErrorUtil.replaceFatalError { message, _, _ in
            DispatchQueue.main.async {
                assertionMessage = message
                expectation.fulfill()
            }
            // Terminate the current thread after expectation fulfill
            Thread.exit()
            // Since current thread was terminated this code never be executed
            fatalError("It will never be executed")
        }

        // ACT
        // Perform on separate thread to be able terminate this thread after expectation fulfill
        Thread(block: testcase).start()

        waitForExpectations(timeout: 0.1) { _ in
            if let expectedMessage = expectedMessage {
                // ASSERT
                XCTAssertEqual(assertionMessage, expectedMessage)
            } else {
                XCTAssertTrue(true)
            }

            // CLEANUP
            FatalErrorUtil.restoreFatalError()
        }
    }
}
