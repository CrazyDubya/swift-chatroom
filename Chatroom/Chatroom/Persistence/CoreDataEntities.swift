//
//  CoreDataEntities.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import CoreData
import Foundation

// MARK: - UserEntity

@objc(UserEntity)
public class UserEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var username: String
    @NSManaged public var email: String
    @NSManaged public var displayName: String
    @NSManaged public var avatarURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var lastSeen: Date?
    @NSManaged public var chats: NSSet?
    @NSManaged public var sentMessages: NSSet?

    // Convert to domain model
    func toUser() -> User {
        return User(
            id: id,
            username: username,
            email: email,
            displayName: displayName,
            avatarURL: avatarURL,
            createdAt: createdAt,
            lastSeen: lastSeen
        )
    }

    // Create from domain model
    static func from(_ user: User, context: NSManagedObjectContext) -> UserEntity {
        let entity = UserEntity(context: context)
        entity.id = user.id
        entity.username = user.username
        entity.email = user.email
        entity.displayName = user.displayName
        entity.avatarURL = user.avatarURL
        entity.createdAt = user.createdAt
        entity.lastSeen = user.lastSeen
        return entity
    }

    // Update from domain model
    func update(from user: User) {
        username = user.username
        email = user.email
        displayName = user.displayName
        avatarURL = user.avatarURL
        lastSeen = user.lastSeen
    }
}

// MARK: - ChatEntity

@objc(ChatEntity)
public class ChatEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String?
    @NSManaged public var type: String
    @NSManaged public var unreadCount: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var participants: NSSet?
    @NSManaged public var messages: NSSet?
    @NSManaged public var lastMessage: MessageEntity?

    // Convert to domain model
    func toChat() -> Chat {
        let participantsArray = (participants as? Set<UserEntity>)?.map { $0.toUser() } ?? []
        let chatType = Chat.ChatType(rawValue: type) ?? .direct

        return Chat(
            id: id,
            name: name,
            participants: participantsArray,
            type: chatType,
            lastMessage: lastMessage?.toMessage(),
            unreadCount: Int(unreadCount),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // Create from domain model
    static func from(_ chat: Chat, context: NSManagedObjectContext) -> ChatEntity {
        let entity = ChatEntity(context: context)
        entity.id = chat.id
        entity.name = chat.name
        entity.type = chat.type.rawValue
        entity.unreadCount = Int32(chat.unreadCount)
        entity.createdAt = chat.createdAt
        entity.updatedAt = chat.updatedAt

        // Add participants
        for participant in chat.participants {
            let userEntity = UserEntity.from(participant, context: context)
            entity.addToParticipants(userEntity)
        }

        return entity
    }

    // Update from domain model
    func update(from chat: Chat) {
        name = chat.name
        type = chat.type.rawValue
        unreadCount = Int32(chat.unreadCount)
        updatedAt = chat.updatedAt
    }

    // Helper methods for relationships
    @objc(addParticipantsObject:)
    @NSManaged public func addToParticipants(_ value: UserEntity)

    @objc(removeParticipantsObject:)
    @NSManaged public func removeFromParticipants(_ value: UserEntity)

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: MessageEntity)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: MessageEntity)
}

// MARK: - MessageEntity

@objc(MessageEntity)
public class MessageEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var content: String
    @NSManaged public var type: String
    @NSManaged public var mediaURL: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var isRead: Bool
    @NSManaged public var deliveredAt: Date?
    @NSManaged public var readAt: Date?
    @NSManaged public var senderName: String
    @NSManaged public var chat: ChatEntity?
    @NSManaged public var sender: UserEntity?
    @NSManaged public var lastMessageForChat: ChatEntity?

    // Convert to domain model
    func toMessage() -> Message {
        let messageType = Message.MessageType(rawValue: type) ?? .text

        return Message(
            id: id,
            chatId: chat?.id ?? "",
            senderId: sender?.id ?? "",
            senderName: senderName,
            content: content,
            type: messageType,
            mediaURL: mediaURL,
            timestamp: timestamp,
            isRead: isRead,
            deliveredAt: deliveredAt,
            readAt: readAt
        )
    }

    // Create from domain model
    static func from(_ message: Message, context: NSManagedObjectContext) -> MessageEntity {
        let entity = MessageEntity(context: context)
        entity.id = message.id
        entity.content = message.content
        entity.type = message.type.rawValue
        entity.mediaURL = message.mediaURL
        entity.timestamp = message.timestamp
        entity.isRead = message.isRead
        entity.deliveredAt = message.deliveredAt
        entity.readAt = message.readAt
        entity.senderName = message.senderName
        return entity
    }

    // Update from domain model
    func update(from message: Message) {
        content = message.content
        type = message.type.rawValue
        mediaURL = message.mediaURL
        isRead = message.isRead
        deliveredAt = message.deliveredAt
        readAt = message.readAt
    }
}
