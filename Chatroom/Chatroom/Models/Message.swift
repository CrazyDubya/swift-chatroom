//
//  Message.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let chatId: String
    let senderId: String
    var senderName: String
    var content: String
    var type: MessageType
    var mediaURL: String?
    var timestamp: Date
    var isRead: Bool
    var deliveredAt: Date?
    var readAt: Date?

    enum MessageType: String, Codable {
        case text
        case image
        case video
        case audio
        case file
        case system
    }

    enum CodingKeys: String, CodingKey {
        case id
        case chatId = "chat_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case content
        case type
        case mediaURL = "media_url"
        case timestamp
        case isRead = "is_read"
        case deliveredAt = "delivered_at"
        case readAt = "read_at"
    }
}

// MARK: - Message Creation
struct SendMessageRequest: Codable {
    let chatId: String
    let content: String
    let type: Message.MessageType
    let mediaURL: String?

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case content
        case type
        case mediaURL = "media_url"
    }
}
