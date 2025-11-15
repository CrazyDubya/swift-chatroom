//
//  UserRepository.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import CoreData
import Foundation

class UserRepository {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Fetch Operations

    func fetchAllUsers() -> [User] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.username, ascending: true)]

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toUser() }
        } catch {
            print("Failed to fetch users: \(error)")
            return []
        }
    }

    func fetchUser(byId id: String) -> User? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first?.toUser()
        } catch {
            print("Failed to fetch user: \(error)")
            return nil
        }
    }

    func searchUsers(query: String) -> [User] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "username CONTAINS[cd] %@ OR displayName CONTAINS[cd] %@ OR email CONTAINS[cd] %@",
            query, query, query
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.username, ascending: true)]

        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toUser() }
        } catch {
            print("Failed to search users: \(error)")
            return []
        }
    }

    // MARK: - Save Operations

    func saveUser(_ user: User) {
        let context = persistenceController.container.viewContext

        // Check if user already exists
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id)
        fetchRequest.fetchLimit = 1

        do {
            let existingEntities = try context.fetch(fetchRequest)

            if let existingEntity = existingEntities.first {
                // Update existing
                existingEntity.update(from: user)
            } else {
                // Create new
                _ = UserEntity.from(user, context: context)
            }

            persistenceController.save()
        } catch {
            print("Failed to save user: \(error)")
        }
    }

    func saveUsers(_ users: [User]) {
        for user in users {
            saveUser(user)
        }
    }

    // MARK: - Update Operations

    func updateLastSeen(userId: String, lastSeen: Date) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
        fetchRequest.fetchLimit = 1

        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.lastSeen = lastSeen
                persistenceController.save()
            }
        } catch {
            print("Failed to update last seen: \(error)")
        }
    }

    // MARK: - Delete Operations

    func deleteUser(byId id: String) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            persistenceController.save()
        } catch {
            print("Failed to delete user: \(error)")
        }
    }

    func clearAllUsers() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = UserEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            persistenceController.save()
        } catch {
            print("Failed to clear users: \(error)")
        }
    }
}
