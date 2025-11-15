//
//  SyncService.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import Combine

class SyncService {
    static let shared = SyncService()

    private let apiClient: APIClient
    private let chatRepository: ChatRepository
    private let messageRepository: MessageRepository
    private let userRepository: UserRepository

    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false

    private init(
        apiClient: APIClient = .shared,
        chatRepository: ChatRepository = ChatRepository(),
        messageRepository: MessageRepository = MessageRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.apiClient = apiClient
        self.chatRepository = chatRepository
        self.messageRepository = messageRepository
        self.userRepository = userRepository
    }

    // MARK: - Sync Methods

    func syncChats() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            // Fetch chats from API
            let remoteChats = try await apiClient.fetchChats()

            // Save to local database
            chatRepository.saveChats(remoteChats)

            // Sync users from chats
            for chat in remoteChats {
                userRepository.saveUsers(chat.participants)
            }
        } catch {
            print("Failed to sync chats: \(error)")
            throw error
        }
    }

    func syncMessages(forChatId chatId: String) async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            // Fetch messages from API
            let remoteMessages = try await apiClient.fetchMessages(chatId: chatId)

            // Save to local database
            messageRepository.saveMessages(remoteMessages)

            // Update chat's last message
            if let lastMessage = remoteMessages.last,
               let chat = chatRepository.fetchChat(byId: chatId) {
                var updatedChat = chat
                updatedChat.lastMessage = lastMessage
                chatRepository.saveChat(updatedChat)
            }
        } catch {
            print("Failed to sync messages: \(error)")
            throw error
        }
    }

    func syncAll() async throws {
        try await syncChats()

        // Sync messages for all chats
        let chats = chatRepository.fetchAllChats()
        for chat in chats {
            try await syncMessages(forChatId: chat.id)
        }
    }

    // MARK: - Offline Queue

    private var pendingMessages: [Message] = []

    func queueMessage(_ message: Message) {
        // Save to local database immediately
        messageRepository.saveMessage(message)
        pendingMessages.append(message)

        // Try to send if online
        Task {
            await sendPendingMessages()
        }
    }

    func sendPendingMessages() async {
        guard !pendingMessages.isEmpty else { return }

        var successfulMessages: [String] = []

        for message in pendingMessages {
            do {
                _ = try await apiClient.sendMessage(
                    chatId: message.chatId,
                    content: message.content,
                    type: message.type,
                    mediaURL: message.mediaURL
                )
                successfulMessages.append(message.id)
            } catch {
                print("Failed to send pending message: \(error)")
                // Keep in queue for retry
            }
        }

        // Remove successfully sent messages
        pendingMessages.removeAll { successfulMessages.contains($0.id) }
    }

    // MARK: - Cache Management

    func clearCache() {
        chatRepository.clearAllChats()
        messageRepository.clearAllMessages()
        userRepository.clearAllUsers()
    }

    func getCacheSize() -> Int64 {
        // Calculate total size of Core Data store
        guard let storeURL = PersistenceController.shared.container.persistentStoreCoordinator.persistentStores.first?.url else {
            return 0
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    // MARK: - Offline Support

    func loadOfflineChats() -> [Chat] {
        return chatRepository.fetchAllChats()
    }

    func loadOfflineMessages(forChatId chatId: String) -> [Message] {
        return messageRepository.fetchMessages(forChatId: chatId)
    }

    func isDataAvailableOffline() -> Bool {
        return !chatRepository.fetchAllChats().isEmpty
    }
}
