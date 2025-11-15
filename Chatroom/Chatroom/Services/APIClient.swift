//
//  APIClient.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)
}

class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://api.chatroom.example.com/v1"
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Method

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication token if required
        if authenticated, let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Encode body if present
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            case 401:
                throw APIError.unauthorized
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(errorMessage)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Chat Endpoints

    func fetchChats() async throws -> [Chat] {
        return try await request(endpoint: "/chats")
    }

    func createChat(participantIds: [String], type: Chat.ChatType, name: String?) async throws -> Chat {
        let body = CreateChatRequest(participantIds: participantIds, type: type, name: name)
        return try await request(endpoint: "/chats", method: "POST", body: body)
    }

    // MARK: - Message Endpoints

    func fetchMessages(chatId: String) async throws -> [Message] {
        return try await request(endpoint: "/chats/\(chatId)/messages")
    }

    func sendMessage(chatId: String, content: String, type: Message.MessageType, mediaURL: String? = nil) async throws -> Message {
        let body = SendMessageRequest(chatId: chatId, content: content, type: type, mediaURL: mediaURL)
        return try await request(endpoint: "/chats/\(chatId)/messages", method: "POST", body: body)
    }

    func markMessageAsRead(messageId: String) async throws {
        let _: EmptyResponse = try await request(endpoint: "/messages/\(messageId)/read", method: "PUT")
    }

    // MARK: - User Endpoints

    func fetchUsers(search: String? = nil) async throws -> [User] {
        var endpoint = "/users"
        if let search = search {
            endpoint += "?search=\(search)"
        }
        return try await request(endpoint: endpoint)
    }

    func fetchUser(id: String) async throws -> User {
        return try await request(endpoint: "/users/\(id)")
    }
}

// MARK: - Helper Types

private struct EmptyResponse: Codable {}
