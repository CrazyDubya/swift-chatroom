//
//  AuthViewModelTests.swift
//  ChatroomTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
@testable import Chatroom

@MainActor
final class AuthViewModelTests: XCTestCase {
    var sut: AuthViewModel!
    var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        sut = AuthViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Login Tests

    func testLogin_Success() async {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = true

        // When
        await sut.login(email: email, password: password)

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.email, email)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_Failure() async {
        // Given
        let email = "test@example.com"
        let password = "wrongpassword"
        mockAuthService.shouldSucceed = false

        // When
        await sut.login(email: email, password: password)

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_EmptyCredentials() async {
        // Given
        let email = ""
        let password = ""

        // When
        await sut.login(email: email, password: password)

        // Then
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: - Register Tests

    func testRegister_Success() async {
        // Given
        let username = "testuser"
        let email = "test@example.com"
        let password = "password123"
        let displayName = "Test User"
        mockAuthService.shouldSucceed = true

        // When
        await sut.register(username: username, email: email, password: password, displayName: displayName)

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.username, username)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testRegister_Failure() async {
        // Given
        let username = "testuser"
        let email = "test@example.com"
        let password = "password123"
        let displayName = "Test User"
        mockAuthService.shouldSucceed = false

        // When
        await sut.register(username: username, email: email, password: password, displayName: displayName)

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Logout Tests

    func testLogout() async {
        // Given
        mockAuthService.shouldSucceed = true
        await sut.login(email: "test@example.com", password: "password123")
        XCTAssertTrue(sut.isAuthenticated)

        // When
        sut.logout()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }
}

// MARK: - Mock Auth Service

class MockAuthService: AuthService {
    var shouldSucceed = true

    override func login(email: String, password: String) async throws -> AuthResponse {
        if shouldSucceed {
            let user = User(
                id: "test_user",
                username: "testuser",
                email: email,
                displayName: "Test User",
                createdAt: Date()
            )
            return AuthResponse(user: user, token: "mock_token", refreshToken: nil)
        } else {
            throw APIError.unauthorized
        }
    }

    override func register(username: String, email: String, password: String, displayName: String) async throws -> AuthResponse {
        if shouldSucceed {
            let user = User(
                id: "test_user",
                username: username,
                email: email,
                displayName: displayName,
                createdAt: Date()
            )
            return AuthResponse(user: user, token: "mock_token", refreshToken: nil)
        } else {
            throw APIError.serverError("Registration failed")
        }
    }

    override func logout() {
        authToken = nil
        refreshToken = nil
    }
}
