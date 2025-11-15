//
//  ForwardMessageView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct ForwardMessageView: View {
    let message: Message
    @StateObject private var viewModel = ForwardMessageViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Original Message Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Forward Message")
                        .font(.headline)

                    MessagePreview(message: message)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                // Chat List
                List {
                    Section("Recent Chats") {
                        ForEach(viewModel.chats) { chat in
                            ChatSelectRow(
                                chat: chat,
                                isSelected: viewModel.selectedChats.contains(where: { $0.id == chat.id })
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.toggleChat(chat)
                            }
                        }
                    }
                }

                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    Button("Forward") {
                        Task {
                            if await viewModel.forwardMessage(message) {
                                dismiss()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canForward ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!viewModel.canForward || viewModel.isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadChats()
        }
    }
}

struct MessagePreview: View {
    let message: Message

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(message.content)
                    .lineLimit(2)
            }

            Spacer()

            if message.type != .text {
                Image(systemName: iconForMessageType(message.type))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func iconForMessageType(_ type: Message.MessageType) -> String {
        switch type {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .file: return "doc"
        default: return "text.bubble"
        }
    }
}

struct ChatSelectRow: View {
    let chat: Chat
    let isSelected: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(chat.displayName.prefix(1))
                        .foregroundColor(.blue)
                )

            Text(chat.displayName)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Forward Message ViewModel

@MainActor
class ForwardMessageViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var selectedChats: [Chat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let chatRepository = ChatRepository()
    private let apiClient = APIClient.shared

    var canForward: Bool {
        !selectedChats.isEmpty
    }

    func loadChats() async {
        isLoading = true

        // Load from local first
        chats = chatRepository.fetchAllChats()

        // Then sync
        do {
            let remoteChats = try await apiClient.fetchChats()
            chatRepository.saveChats(remoteChats)
            chats = chatRepository.fetchAllChats()
        } catch {
            // Use offline data
        }

        isLoading = false
    }

    func toggleChat(_ chat: Chat) {
        if let index = selectedChats.firstIndex(where: { $0.id == chat.id }) {
            selectedChats.remove(at: index)
        } else {
            selectedChats.append(chat)
        }
    }

    func forwardMessage(_ message: Message) async -> Bool {
        isLoading = true
        errorMessage = nil

        var allSucceeded = true

        for chat in selectedChats {
            do {
                _ = try await apiClient.sendMessage(
                    chatId: chat.id,
                    content: message.content,
                    type: message.type,
                    mediaURL: message.mediaURL
                )

                AnalyticsService.shared.trackMessageSent(chatId: chat.id, messageType: message.type)
                AnalyticsService.shared.logEvent(.messageForwarded, parameters: [
                    "original_chat_id": message.chatId,
                    "target_chat_id": chat.id
                ])
            } catch {
                allSucceeded = false
                errorMessage = "Failed to forward to some chats"
            }
        }

        isLoading = false
        return allSucceeded
    }
}

#Preview {
    ForwardMessageView(message: Message(
        id: "1",
        chatId: "1",
        senderId: "1",
        senderName: "John",
        content: "Check this out!",
        type: .text,
        timestamp: Date(),
        isRead: false
    ))
}
