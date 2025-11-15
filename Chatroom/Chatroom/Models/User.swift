//
//  User.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String
    var email: String
    var displayName: String
    var avatarURL: String?
    var createdAt: Date
    var lastSeen: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case lastSeen = "last_seen"
    }
}

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case username
        case email
        case password
        case displayName = "display_name"
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case user
        case token
        case refreshToken = "refresh_token"
    }
}
