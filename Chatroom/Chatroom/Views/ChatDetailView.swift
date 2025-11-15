//
//  ChatDetailView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    @StateObject private var chatViewModel = ChatViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(chatViewModel.messages) { message in
                            MessageRow(
                                message: message,
                                currentUserId: authViewModel.currentUser?.id ?? ""
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatViewModel.messages.count) { _ in
                    if let lastMessage = chatViewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Message Input
            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .focused($isInputFocused)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(chat.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await chatViewModel.loadMessages(for: chat.id)
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        Task {
            await chatViewModel.sendMessage(chatId: chat.id, content: text)
            messageText = ""
        }
    }
}

#Preview {
    NavigationView {
        ChatDetailView(chat: Chat(
            id: "1",
            name: "Test Chat",
            participants: [],
            type: .direct,
            lastMessage: nil,
            unreadCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        ))
        .environmentObject(AuthViewModel())
    }
}
