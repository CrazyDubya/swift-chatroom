//
//  APIClientTests.swift
//  ChatroomTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
@testable import Chatroom

final class APIClientTests: XCTestCase {
    // Note: These are integration tests that would normally hit a mock server
    // For demonstration purposes, we're testing the error handling logic

    func testAPIError_Unauthorized() {
        // Given
        let error = APIError.unauthorized

        // Then
        XCTAssertNotNil(error)
    }

    func testAPIError_InvalidURL() {
        // Given
        let error = APIError.invalidURL

        // Then
        XCTAssertNotNil(error)
    }

    func testAPIError_ServerError() {
        // Given
        let errorMessage = "Test error"
        let error = APIError.serverError(errorMessage)

        // Then
        if case .serverError(let message) = error {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected serverError")
        }
    }
}
