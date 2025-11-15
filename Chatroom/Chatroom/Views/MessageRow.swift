//
//  MessageRow.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct MessageRow: View {
    let message: Message
    let currentUserId: String

    private var isCurrentUser: Bool {
        message.senderId == currentUserId
    }

    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                MessageBubble(message: message, isCurrentUser: isCurrentUser)

                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if isCurrentUser {
                        if message.readAt != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        } else if message.deliveredAt != nil {
                            Image(systemName: "checkmark.circle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "circle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !isCurrentUser {
                Spacer()
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        Text(message.content)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrentUser ? Color.blue : Color(.systemGray5))
            .foregroundColor(isCurrentUser ? .white : .primary)
            .cornerRadius(16)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageRow(
            message: Message(
                id: "1",
                chatId: "1",
                senderId: "1",
                senderName: "John Doe",
                content: "Hello! This is a test message.",
                type: .text,
                timestamp: Date(),
                isRead: false
            ),
            currentUserId: "1"
        )

        MessageRow(
            message: Message(
                id: "2",
                chatId: "1",
                senderId: "2",
                senderName: "Jane Smith",
                content: "This is another message from a different user.",
                type: .text,
                timestamp: Date(),
                isRead: true
            ),
            currentUserId: "1"
        )
    }
    .padding()
}
