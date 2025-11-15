//
//  ChatViewModel.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: APIClient
    private let webSocketManager: WebSocketManager
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: APIClient = .shared, webSocketManager: WebSocketManager = .shared) {
        self.apiClient = apiClient
        self.webSocketManager = webSocketManager
        setupWebSocketListeners()
    }

    // MARK: - Chat List Methods

    func loadChats() async {
        isLoading = true
        errorMessage = nil

        do {
            chats = try await apiClient.fetchChats()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func createChat(participantIds: [String], type: Chat.ChatType, name: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let newChat = try await apiClient.createChat(
                participantIds: participantIds,
                type: type,
                name: name
            )
            chats.insert(newChat, at: 0)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Message Methods

    func loadMessages(for chatId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            messages = try await apiClient.fetchMessages(chatId: chatId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func sendMessage(chatId: String, content: String, type: Message.MessageType = .text) async {
        do {
            let newMessage = try await apiClient.sendMessage(
                chatId: chatId,
                content: content,
                type: type
            )
            messages.append(newMessage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markMessageAsRead(_ messageId: String) async {
        do {
            try await apiClient.markMessageAsRead(messageId: messageId)
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].isRead = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - WebSocket Setup

    private func setupWebSocketListeners() {
        webSocketManager.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleNewMessage(message)
            }
            .store(in: &cancellables)
    }

    private func handleNewMessage(_ message: Message) {
        messages.append(message)

        // Update chat's last message
        if let chatIndex = chats.firstIndex(where: { $0.id == message.chatId }) {
            var updatedChat = chats[chatIndex]
            updatedChat.lastMessage = message
            updatedChat.unreadCount += 1
            chats[chatIndex] = updatedChat
        }
    }
}
