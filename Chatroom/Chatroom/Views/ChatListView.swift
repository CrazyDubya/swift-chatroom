//
//  ChatListView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showingNewChat = false

    var body: some View {
        NavigationView {
            ZStack {
                if chatViewModel.isLoading && chatViewModel.chats.isEmpty {
                    ProgressView("Loading chats...")
                } else if chatViewModel.chats.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(chatViewModel.chats) { chat in
                            NavigationLink(destination: ChatDetailView(chat: chat)) {
                                ChatRowView(chat: chat)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewChat = true
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView()
                    .environmentObject(chatViewModel)
            }
            .task {
                await chatViewModel.loadChats()
            }
            .refreshable {
                await chatViewModel.loadChats()
            }
        }
    }
}

// MARK: - Chat Row View

struct ChatRowView: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(chat.displayName.prefix(1))
                        .font(.title2)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            if chat.unreadCount > 0 {
                Spacer()
                Text("\(chat.unreadCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)

            Text("No Chats Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a new conversation by tapping the compose button")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - New Chat View

struct NewChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatViewModel: ChatViewModel

    var body: some View {
        NavigationView {
            VStack {
                Text("New Chat Feature")
                    .font(.headline)
                Text("This will allow searching for users and creating new chats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatListView()
        .environmentObject(AuthViewModel())
}
