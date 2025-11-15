//
//  Chat.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

struct Chat: Identifiable, Codable, Equatable {
    let id: String
    var name: String?
    var participants: [User]
    var type: ChatType
    var lastMessage: Message?
    var unreadCount: Int
    var createdAt: Date
    var updatedAt: Date

    enum ChatType: String, Codable {
        case direct
        case group
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case participants
        case type
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed property for display name in direct chats
    var displayName: String {
        if let name = name {
            return name
        }

        // For direct chats, show the other participant's name
        if type == .direct, let otherUser = participants.first {
            return otherUser.displayName
        }

        return "Unknown Chat"
    }
}

// MARK: - Chat Creation
struct CreateChatRequest: Codable {
    let participantIds: [String]
    let type: Chat.ChatType
    let name: String?

    enum CodingKeys: String, CodingKey {
        case participantIds = "participant_ids"
        case type
        case name
    }
}
