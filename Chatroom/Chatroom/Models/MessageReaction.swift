//
//  MessageReaction.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

struct MessageReaction: Identifiable, Codable, Equatable {
    let id: String
    let messageId: String
    let userId: String
    let userName: String
    let emoji: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case messageId = "message_id"
        case userId = "user_id"
        case userName = "user_name"
        case emoji
        case timestamp
    }
}

// MARK: - Reaction Group

struct ReactionGroup: Identifiable {
    let id: String
    let emoji: String
    var users: [String] // User IDs
    var count: Int { users.count }

    init(emoji: String, users: [String] = []) {
        self.id = emoji
        self.emoji = emoji
        self.users = users
    }
}

// MARK: - Message Extension

extension Message {
    var reactions: [MessageReaction]? {
        get { nil } // This would come from a separate fetch
        set { }
    }

    func groupedReactions(_ reactions: [MessageReaction]) -> [ReactionGroup] {
        var groups: [String: ReactionGroup] = [:]

        for reaction in reactions {
            if var group = groups[reaction.emoji] {
                group.users.append(reaction.userId)
                groups[reaction.emoji] = group
            } else {
                groups[reaction.emoji] = ReactionGroup(
                    emoji: reaction.emoji,
                    users: [reaction.userId]
                )
            }
        }

        return Array(groups.values).sorted { $0.count > $1.count }
    }
}

// MARK: - Popular Reactions

struct PopularReactions {
    static let emojis = ["❤️", "👍", "😂", "😮", "😢", "🙏", "🎉", "🔥"]
}
