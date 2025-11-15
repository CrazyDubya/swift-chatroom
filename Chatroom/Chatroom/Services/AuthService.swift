//
//  AuthService.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import Security

class AuthService {
    static let shared = AuthService()

    private let baseURL = "https://api.chatroom.example.com/v1"
    private let tokenKey = "auth_token"
    private let refreshTokenKey = "refresh_token"

    private init() {}

    var authToken: String? {
        get { KeychainHelper.get(key: tokenKey) }
        set {
            if let token = newValue {
                KeychainHelper.save(key: tokenKey, value: token)
            } else {
                KeychainHelper.delete(key: tokenKey)
            }
        }
    }

    var refreshToken: String? {
        get { KeychainHelper.get(key: refreshTokenKey) }
        set {
            if let token = newValue {
                KeychainHelper.save(key: refreshTokenKey, value: token)
            } else {
                KeychainHelper.delete(key: refreshTokenKey)
            }
        }
    }

    var isAuthenticated: Bool {
        return authToken != nil
    }

    // MARK: - Authentication Methods

    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: baseURL + "/auth/login") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.unauthorized
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let authResponse = try decoder.decode(AuthResponse.self, from: data)

        // Store tokens
        authToken = authResponse.token
        refreshToken = authResponse.refreshToken

        return authResponse
    }

    func register(username: String, email: String, password: String, displayName: String) async throws -> AuthResponse {
        guard let url = URL(string: baseURL + "/auth/register") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RegisterRequest(username: username, email: email, password: password, displayName: displayName)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.serverError("Registration failed")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let authResponse = try decoder.decode(AuthResponse.self, from: data)

        // Store tokens
        authToken = authResponse.token
        refreshToken = authResponse.refreshToken

        return authResponse
    }

    func logout() {
        authToken = nil
        refreshToken = nil
    }

    func getCurrentUser() async throws -> User {
        guard let url = URL(string: baseURL + "/users/me") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to fetch user")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(User.self, from: data)
    }
}

// MARK: - Keychain Helper

private class KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
