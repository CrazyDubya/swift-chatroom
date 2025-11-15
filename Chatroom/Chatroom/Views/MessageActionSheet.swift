//
//  MessageActionSheet.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct MessageActionSheet: View {
    let message: Message
    let onReact: (String) -> Void
    let onReply: () -> Void
    let onForward: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Quick Reactions
            HStack(spacing: 16) {
                ForEach(PopularReactions.emojis, id: \.self) { emoji in
                    Button(action: {
                        onReact(emoji)
                        dismiss()
                    }) {
                        Text(emoji)
                            .font(.system(size: 32))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Action Buttons
            VStack(spacing: 0) {
                ActionButton(
                    icon: "arrowshape.turn.up.left",
                    title: "Reply",
                    action: {
                        onReply()
                        dismiss()
                    }
                )

                ActionButton(
                    icon: "arrowshape.turn.up.forward",
                    title: "Forward",
                    action: {
                        onForward()
                        dismiss()
                    }
                )

                ActionButton(
                    icon: "doc.on.doc",
                    title: "Copy",
                    action: {
                        onCopy()
                        dismiss()
                    }
                )

                if message.senderId == "current_user_id" { // TODO: Check actual user ID
                    ActionButton(
                        icon: "pencil",
                        title: "Edit",
                        action: {
                            onEdit()
                            dismiss()
                        }
                    )

                    ActionButton(
                        icon: "trash",
                        title: "Delete",
                        destructive: true,
                        action: {
                            onDelete()
                            dismiss()
                        }
                    )
                }
            }
            .background(Color(.systemBackground))
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(destructive ? .red : .blue)

                Text(title)
                    .foregroundColor(destructive ? .red : .primary)

                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }

        Divider()
            .padding(.leading, 52)
    }
}

#Preview {
    MessageActionSheet(
        message: Message(
            id: "1",
            chatId: "1",
            senderId: "1",
            senderName: "Test",
            content: "Test message",
            type: .text,
            timestamp: Date(),
            isRead: false
        ),
        onReact: { _ in },
        onReply: {},
        onForward: {},
        onEdit: {},
        onDelete: {},
        onCopy: {}
    )
}
