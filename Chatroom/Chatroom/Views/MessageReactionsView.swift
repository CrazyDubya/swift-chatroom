//
//  MessageReactionsView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct MessageReactionsView: View {
    let reactions: [MessageReaction]
    let currentUserId: String
    let onTapReaction: (String) -> Void

    private var groupedReactions: [ReactionGroup] {
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

    var body: some View {
        if !reactions.isEmpty {
            HStack(spacing: 6) {
                ForEach(groupedReactions) { group in
                    ReactionPill(
                        group: group,
                        isReactedByCurrentUser: group.users.contains(currentUserId),
                        onTap: {
                            onTapReaction(group.emoji)
                        }
                    )
                }
            }
            .padding(.top, 4)
        }
    }
}

struct ReactionPill: View {
    let group: ReactionGroup
    let isReactedByCurrentUser: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(group.emoji)
                    .font(.caption)

                if group.count > 1 {
                    Text("\(group.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isReactedByCurrentUser
                    ? Color.blue.opacity(0.2)
                    : Color(.systemGray6)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isReactedByCurrentUser ? Color.blue : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Reaction Detail View

struct ReactionDetailView: View {
    let reactions: [MessageReaction]
    @Environment(\.dismiss) var dismiss

    private var groupedReactions: [ReactionGroup] {
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

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedReactions) { group in
                    Section(header: Text("\(group.emoji) \(group.count)")) {
                        ForEach(reactions.filter { $0.emoji == group.emoji }) { reaction in
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(reaction.userName.prefix(1))
                                            .foregroundColor(.blue)
                                    )

                                VStack(alignment: .leading) {
                                    Text(reaction.userName)
                                        .font(.body)

                                    Text(reaction.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MessageReactionsView(
        reactions: [
            MessageReaction(
                id: "1",
                messageId: "msg1",
                userId: "user1",
                userName: "John",
                emoji: "❤️",
                timestamp: Date()
            ),
            MessageReaction(
                id: "2",
                messageId: "msg1",
                userId: "user2",
                userName: "Jane",
                emoji: "❤️",
                timestamp: Date()
            ),
            MessageReaction(
                id: "3",
                messageId: "msg1",
                userId: "user3",
                userName: "Bob",
                emoji: "👍",
                timestamp: Date()
            )
        ],
        currentUserId: "user1",
        onTapReaction: { _ in }
    )
}
