//
//  MessageRepository.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import CoreData
import Foundation

class MessageRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Fetch Operations

    func fetchMessages(forChatId chatId: String, limit: Int = 100) -> [Message] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chat.id == %@", chatId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.timestamp, ascending: true)]
        fetchRequest.fetchLimit = limit

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toMessage() }
        } catch {
            print("Failed to fetch messages: \(error)")
            return []
        }
    }

    func fetchMessage(byId id: String) -> Message? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first?.toMessage()
        } catch {
            print("Failed to fetch message: \(error)")
            return nil
        }
    }

    func fetchUnreadMessages(forChatId chatId: String) -> [Message] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chat.id == %@ AND isRead == NO", chatId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.timestamp, ascending: true)]

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toMessage() }
        } catch {
            print("Failed to fetch unread messages: \(error)")
            return []
        }
    }

    // MARK: - Save Operations

    func saveMessage(_ message: Message) {
        let context = persistenceController.container.viewContext

        // Check if message already exists
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", message.id)
        fetchRequest.fetchLimit = 1

        do {
            let existingEntities = try context.fetch(fetchRequest)

            if let existingEntity = existingEntities.first {
                // Update existing
                existingEntity.update(from: message)
            } else {
                // Create new
                let messageEntity = MessageEntity.from(message, context: context)

                // Link to chat
                let chatFetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
                chatFetchRequest.predicate = NSPredicate(format: "id == %@", message.chatId)
                chatFetchRequest.fetchLimit = 1

                if let chatEntity = try context.fetch(chatFetchRequest).first {
                    messageEntity.chat = chatEntity
                    chatEntity.addToMessages(messageEntity)
                    chatEntity.lastMessage = messageEntity
                    chatEntity.updatedAt = message.timestamp
                }

                // Link to sender
                let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                userFetchRequest.predicate = NSPredicate(format: "id == %@", message.senderId)
                userFetchRequest.fetchLimit = 1

                if let userEntity = try context.fetch(userFetchRequest).first {
                    messageEntity.sender = userEntity
                }
            }

            persistenceController.save()
        } catch {
            print("Failed to save message: \(error)")
        }
    }

    func saveMessages(_ messages: [Message]) {
        for message in messages {
            saveMessage(message)
        }
    }

    // MARK: - Update Operations

    func markMessageAsRead(_ messageId: String) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", messageId)
        fetchRequest.fetchLimit = 1

        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.isRead = true
                entity.readAt = Date()
                persistenceController.save()
            }
        } catch {
            print("Failed to mark message as read: \(error)")
        }
    }

    func markAllMessagesAsRead(forChatId chatId: String) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chat.id == %@ AND isRead == NO", chatId)

        do {
            let entities = try context.fetch(fetchRequest)
            let now = Date()
            for entity in entities {
                entity.isRead = true
                entity.readAt = now
            }
            persistenceController.save()
        } catch {
            print("Failed to mark messages as read: \(error)")
        }
    }

    // MARK: - Delete Operations

    func deleteMessage(byId id: String) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            persistenceController.save()
        } catch {
            print("Failed to delete message: \(error)")
        }
    }

    func deleteMessages(forChatId chatId: String) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chat.id == %@", chatId)

        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            persistenceController.save()
        } catch {
            print("Failed to delete messages: \(error)")
        }
    }

    func clearAllMessages() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MessageEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            persistenceController.save()
        } catch {
            print("Failed to clear messages: \(error)")
        }
    }
}
