//
//  ChatViewModelTests.swift
//  ChatroomTests
//
//  Created by Claude on 2025-11-15.
//

import XCTest
import Combine
@testable import Chatroom

@MainActor
final class ChatViewModelTests: XCTestCase {
    var sut: ChatViewModel!
    var mockAPIClient: MockAPIClient!
    var mockSyncService: MockSyncService!
    var mockChatRepository: MockChatRepository!
    var mockMessageRepository: MockMessageRepository!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        mockSyncService = MockSyncService()
        mockChatRepository = MockChatRepository()
        mockMessageRepository = MockMessageRepository()

        sut = ChatViewModel(
            apiClient: mockAPIClient,
            webSocketManager: .shared,
            syncService: mockSyncService,
            chatRepository: mockChatRepository,
            messageRepository: mockMessageRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        mockSyncService = nil
        mockChatRepository = nil
        mockMessageRepository = nil
        super.tearDown()
    }

    // MARK: - Load Chats Tests

    func testLoadChats_Success() async {
        // Given
        let mockChats = [createMockChat()]
        mockChatRepository.chats = mockChats
        mockSyncService.shouldSucceed = true

        // When
        await sut.loadChats()

        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.chats.count, 1)
        XCTAssertFalse(sut.isOffline)
        XCTAssertTrue(mockSyncService.syncChatsCalled)
    }

    func testLoadChats_OfflineMode() async {
        // Given
        let mockChats = [createMockChat()]
        mockChatRepository.chats = mockChats
        mockSyncService.shouldSucceed = false

        // When
        await sut.loadChats()

        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.chats.count, 1)
        XCTAssertTrue(sut.isOffline)
    }

    // MARK: - Send Message Tests

    func testSendMessage_Success() async {
        // Given
        let chatId = "chat_1"
        let content = "Test message"
        mockAPIClient.shouldSucceed = true

        // When
        await sut.sendMessage(chatId: chatId, content: content)

        // Then
        XCTAssertFalse(sut.messages.isEmpty)
        XCTAssertTrue(mockMessageRepository.saveMessageCalled)
    }

    func testSendMessage_Offline() async {
        // Given
        let chatId = "chat_1"
        let content = "Test message"
        mockAPIClient.shouldSucceed = false

        // When
        await sut.sendMessage(chatId: chatId, content: content)

        // Then
        XCTAssertFalse(sut.messages.isEmpty)
        XCTAssertTrue(mockSyncService.queueMessageCalled)
    }

    // MARK: - Load Messages Tests

    func testLoadMessages_Success() async {
        // Given
        let chatId = "chat_1"
        let mockMessages = [createMockMessage(chatId: chatId)]
        mockMessageRepository.messages = mockMessages
        mockSyncService.shouldSucceed = true

        // When
        await sut.loadMessages(for: chatId)

        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertFalse(sut.isOffline)
    }

    func testMarkMessageAsRead() async {
        // Given
        let message = createMockMessage(chatId: "chat_1")
        sut.messages = [message]

        // When
        await sut.markMessageAsRead(message.id)

        // Then
        XCTAssertTrue(mockMessageRepository.markAsReadCalled)
    }

    // MARK: - Helper Methods

    private func createMockChat() -> Chat {
        return Chat(
            id: "chat_1",
            name: "Test Chat",
            participants: [],
            type: .direct,
            lastMessage: nil,
            unreadCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockMessage(chatId: String) -> Message {
        return Message(
            id: "msg_1",
            chatId: chatId,
            senderId: "user_1",
            senderName: "Test User",
            content: "Test message",
            type: .text,
            timestamp: Date(),
            isRead: false
        )
    }
}

// MARK: - Mock API Client

class MockAPIClient: APIClient {
    var shouldSucceed = true

    override func fetchChats() async throws -> [Chat] {
        if shouldSucceed {
            return []
        } else {
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
    }

    override func sendMessage(chatId: String, content: String, type: Message.MessageType, mediaURL: String?) async throws -> Message {
        if shouldSucceed {
            return Message(
                id: "msg_\(UUID().uuidString)",
                chatId: chatId,
                senderId: "current_user",
                senderName: "Me",
                content: content,
                type: type,
                timestamp: Date(),
                isRead: false
            )
        } else {
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
    }
}

// MARK: - Mock Sync Service

class MockSyncService: SyncService {
    var shouldSucceed = true
    var syncChatsCalled = false
    var queueMessageCalled = false

    override func syncChats() async throws {
        syncChatsCalled = true
        if !shouldSucceed {
            throw APIError.networkError(NSError(domain: "test", code: -1))
        }
    }

    override func queueMessage(_ message: Message) {
        queueMessageCalled = true
    }
}

// MARK: - Mock Repositories

class MockChatRepository: ChatRepository {
    var chats: [Chat] = []

    override func fetchAllChats() -> [Chat] {
        return chats
    }
}

class MockMessageRepository: MessageRepository {
    var messages: [Message] = []
    var saveMessageCalled = false
    var markAsReadCalled = false

    override func fetchMessages(forChatId chatId: String, limit: Int) -> [Message] {
        return messages.filter { $0.chatId == chatId }
    }

    override func saveMessage(_ message: Message) {
        saveMessageCalled = true
        messages.append(message)
    }

    override func markMessageAsRead(_ messageId: String) {
        markAsReadCalled = true
    }
}
