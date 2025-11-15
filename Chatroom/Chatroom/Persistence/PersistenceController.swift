//
//  PersistenceController.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Add sample data for previews
        let viewContext = controller.container.viewContext

        // Create sample user
        let user = UserEntity(context: viewContext)
        user.id = "user_1"
        user.username = "johndoe"
        user.email = "john@example.com"
        user.displayName = "John Doe"
        user.createdAt = Date()

        // Create sample chat
        let chat = ChatEntity(context: viewContext)
        chat.id = "chat_1"
        chat.type = "direct"
        chat.createdAt = Date()
        chat.updatedAt = Date()
        chat.unreadCount = 2

        // Create sample messages
        for i in 1...5 {
            let message = MessageEntity(context: viewContext)
            message.id = "msg_\(i)"
            message.content = "Sample message \(i)"
            message.type = "text"
            message.timestamp = Date().addingTimeInterval(TimeInterval(-i * 60))
            message.isRead = i > 2
            message.senderName = "John Doe"
            message.chat = chat
            message.sender = user
        }

        do {
            try viewContext.save()
        } catch {
            fatalError("Preview data creation failed: \(error)")
        }

        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Chatroom")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save Context

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Background Context

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
