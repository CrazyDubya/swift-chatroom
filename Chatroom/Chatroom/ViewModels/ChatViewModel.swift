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
    @Published var isOffline = false

    private let apiClient: APIClient
    private let webSocketManager: WebSocketManager
    private let syncService: SyncService
    private let chatRepository: ChatRepository
    private let messageRepository: MessageRepository
    private var cancellables = Set<AnyCancellable>()

    init(
        apiClient: APIClient = .shared,
        webSocketManager: WebSocketManager = .shared,
        syncService: SyncService = .shared,
        chatRepository: ChatRepository = ChatRepository(),
        messageRepository: MessageRepository = MessageRepository()
    ) {
        self.apiClient = apiClient
        self.webSocketManager = webSocketManager
        self.syncService = syncService
        self.chatRepository = chatRepository
        self.messageRepository = messageRepository
        setupWebSocketListeners()
        loadOfflineData()
    }

    // MARK: - Chat List Methods

    func loadChats() async {
        isLoading = true
        errorMessage = nil

        // Load from local database first
        chats = chatRepository.fetchAllChats()

        do {
            // Sync with server
            try await syncService.syncChats()
            chats = chatRepository.fetchAllChats()
            isOffline = false
            isLoading = false
        } catch {
            // Fall back to offline data
            errorMessage = "Using offline data"
            isOffline = true
            isLoading = false
        }
    }

    private func loadOfflineData() {
        // Load cached data immediately
        chats = chatRepository.fetchAllChats()
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
            chatRepository.saveChat(newChat)
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

        // Load from local database first
        messages = messageRepository.fetchMessages(forChatId: chatId)

        do {
            // Sync with server
            try await syncService.syncMessages(forChatId: chatId)
            messages = messageRepository.fetchMessages(forChatId: chatId)
            isOffline = false
            isLoading = false
        } catch {
            // Fall back to offline data
            errorMessage = "Using offline messages"
            isOffline = true
            isLoading = false
        }
    }

    func sendMessage(chatId: String, content: String, type: Message.MessageType = .text, mediaURL: String? = nil) async {
        // Create temporary message
        let tempMessage = Message(
            id: UUID().uuidString,
            chatId: chatId,
            senderId: AuthService.shared.authToken ?? "",
            senderName: "Me",
            content: content,
            type: type,
            mediaURL: mediaURL,
            timestamp: Date(),
            isRead: false
        )

        // Add to UI immediately
        messages.append(tempMessage)

        do {
            let newMessage = try await apiClient.sendMessage(
                chatId: chatId,
                content: content,
                type: type,
                mediaURL: mediaURL
            )

            // Replace temp message with real one
            if let index = messages.firstIndex(where: { $0.id == tempMessage.id }) {
                messages[index] = newMessage
            }

            // Save to local database
            messageRepository.saveMessage(newMessage)
        } catch {
            // Queue for later if offline
            syncService.queueMessage(tempMessage)
            errorMessage = "Message queued for sending"
        }
    }

    func markMessageAsRead(_ messageId: String) async {
        // Update locally immediately
        messageRepository.markMessageAsRead(messageId)
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].isRead = true
        }

        // Sync with server
        do {
            try await apiClient.markMessageAsRead(messageId: messageId)
        } catch {
            // Will sync later
            print("Failed to mark as read on server: \(error)")
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
        // Save to local database
        messageRepository.saveMessage(message)

        // Update UI
        messages.append(message)

        // Update chat's last message
        if let chatIndex = chats.firstIndex(where: { $0.id == message.chatId }) {
            var updatedChat = chats[chatIndex]
            updatedChat.lastMessage = message
            updatedChat.unreadCount += 1
            chats[chatIndex] = updatedChat
            chatRepository.saveChat(updatedChat)
        }
    }

    // MARK: - Offline Support

    func syncAllData() async {
        do {
            try await syncService.syncAll()
            chats = chatRepository.fetchAllChats()
            isOffline = false
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }
    }

    func clearCache() {
        syncService.clearCache()
        chats = []
        messages = []
    }
}
