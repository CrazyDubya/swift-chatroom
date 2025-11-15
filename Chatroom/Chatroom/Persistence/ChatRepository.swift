//
//  ChatRepository.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import CoreData
import Foundation

class ChatRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Fetch Operations

    func fetchAllChats() -> [Chat] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChatEntity.updatedAt, ascending: false)]

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toChat() }
        } catch {
            print("Failed to fetch chats: \(error)")
            return []
        }
    }

    func fetchChat(byId id: String) -> Chat? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first?.toChat()
        } catch {
            print("Failed to fetch chat: \(error)")
            return nil
        }
    }

    // MARK: - Save Operations

    func saveChat(_ chat: Chat) {
        let context = persistenceController.container.viewContext

        // Check if chat already exists
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", chat.id)
        fetchRequest.fetchLimit = 1

        do {
            let existingEntities = try context.fetch(fetchRequest)

            if let existingEntity = existingEntities.first {
                // Update existing
                existingEntity.update(from: chat)
            } else {
                // Create new
                _ = ChatEntity.from(chat, context: context)
            }

            persistenceController.save()
        } catch {
            print("Failed to save chat: \(error)")
        }
    }

    func saveChats(_ chats: [Chat]) {
        for chat in chats {
            saveChat(chat)
        }
    }

    // MARK: - Delete Operations

    func deleteChat(byId id: String) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            persistenceController.save()
        } catch {
            print("Failed to delete chat: \(error)")
        }
    }

    // MARK: - Update Operations

    func updateUnreadCount(chatId: String, count: Int) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<ChatEntity> = ChatEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", chatId)
        fetchRequest.fetchLimit = 1

        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.unreadCount = Int32(count)
                persistenceController.save()
            }
        } catch {
            print("Failed to update unread count: \(error)")
        }
    }

    func clearAllChats() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ChatEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            persistenceController.save()
        } catch {
            print("Failed to clear chats: \(error)")
        }
    }
}
