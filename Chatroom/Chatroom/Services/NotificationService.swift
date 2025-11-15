//
//  NotificationService.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import UserNotifications

class NotificationService: NSObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private var deviceToken: String?

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission Request

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await registerForRemoteNotifications()
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func getPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Token Management

    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        // Send token to server
        Task {
            await sendDeviceToken(tokenString)
        }
    }

    private func sendDeviceToken(_ token: String) async {
        // TODO: Send device token to backend
        print("Device token: \(token)")
    }

    // MARK: - Local Notifications

    func scheduleLocalNotification(title: String, body: String, chatId: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let chatId = chatId {
            content.userInfo = ["chatId": chatId]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    func clearBadge() {
        updateBadgeCount(0)
    }

    // MARK: - Notification Handling

    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // Extract chat ID from notification
        if let chatId = userInfo["chatId"] as? String {
            // Navigate to chat
            NotificationCenter.default.post(
                name: .didReceiveChatNotification,
                object: nil,
                userInfo: ["chatId": chatId]
            )
        }
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    func clearNotifications(forChatId chatId: String) {
        center.getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications
                .filter { notification in
                    if let notificationChatId = notification.request.content.userInfo["chatId"] as? String {
                        return notificationChatId == chatId
                    }
                    return false
                }
                .map { $0.request.identifier }

            self.center.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didReceiveChatNotification = Notification.Name("didReceiveChatNotification")
    static let didRegisterForRemoteNotifications = Notification.Name("didRegisterForRemoteNotifications")
}
