//
//  AnalyticsService.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

// MARK: - Analytics Events

enum AnalyticsEvent: String {
    // Authentication
    case loginSuccess = "login_success"
    case loginFailure = "login_failure"
    case registerSuccess = "register_success"
    case registerFailure = "register_failure"
    case logout = "logout"

    // Chat
    case chatOpened = "chat_opened"
    case chatCreated = "chat_created"
    case groupCreated = "group_created"
    case messageSent = "message_sent"
    case messageReceived = "message_received"
    case messageRead = "message_read"
    case messageEdited = "message_edited"
    case messageDeleted = "message_deleted"
    case messageForwarded = "message_forwarded"
    case messageReaction = "message_reaction"

    // Media
    case imageShared = "image_shared"
    case videoShared = "video_shared"
    case voiceMessageSent = "voice_message_sent"
    case fileShared = "file_shared"

    // Features
    case searchPerformed = "search_performed"
    case profileUpdated = "profile_updated"
    case notificationReceived = "notification_received"
    case notificationTapped = "notification_tapped"

    // Performance
    case appLaunched = "app_launched"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
    case crashOccurred = "crash_occurred"

    // Engagement
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case featureDiscovered = "feature_discovered"
}

// MARK: - Analytics Service

class AnalyticsService {
    static let shared = AnalyticsService()

    private var sessionId: String?
    private var sessionStartTime: Date?
    private var userId: String?

    private init() {}

    // MARK: - Session Management

    func startSession(userId: String? = nil) {
        sessionId = UUID().uuidString
        sessionStartTime = Date()
        self.userId = userId

        logEvent(.sessionStarted, parameters: [
            "session_id": sessionId ?? "",
            "user_id": userId ?? "anonymous"
        ])
    }

    func endSession() {
        guard let sessionStartTime = sessionStartTime else { return }

        let sessionDuration = Date().timeIntervalSince(sessionStartTime)

        logEvent(.sessionEnded, parameters: [
            "session_id": sessionId ?? "",
            "duration": sessionDuration
        ])

        sessionId = nil
        self.sessionStartTime = nil
    }

    // MARK: - Event Logging

    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any] = [:]) {
        var enrichedParameters = parameters
        enrichedParameters["timestamp"] = Date().timeIntervalSince1970
        enrichedParameters["session_id"] = sessionId
        enrichedParameters["user_id"] = userId

        // Log to console in debug mode
        #if DEBUG
        print("📊 Analytics: \(event.rawValue)")
        print("   Parameters: \(enrichedParameters)")
        #endif

        // TODO: Send to analytics backend
        // This would typically send to Firebase Analytics, Mixpanel, etc.
        sendToBackend(event: event.rawValue, parameters: enrichedParameters)
    }

    func logScreen(_ screenName: String) {
        logEvent(.featureDiscovered, parameters: [
            "screen_name": screenName
        ])
    }

    // MARK: - User Properties

    func setUserId(_ userId: String) {
        self.userId = userId
    }

    func setUserProperty(_ property: String, value: String) {
        // TODO: Set user properties in analytics backend
        #if DEBUG
        print("📊 User Property: \(property) = \(value)")
        #endif
    }

    // MARK: - Performance Tracking

    func measurePerformance(_ operation: String, block: () -> Void) {
        let startTime = Date()
        block()
        let duration = Date().timeIntervalSince(startTime)

        logEvent(.featureDiscovered, parameters: [
            "operation": operation,
            "duration_ms": duration * 1000
        ])
    }

    func measurePerformanceAsync(_ operation: String, block: () async -> Void) async {
        let startTime = Date()
        await block()
        let duration = Date().timeIntervalSince(startTime)

        logEvent(.featureDiscovered, parameters: [
            "operation": operation,
            "duration_ms": duration * 1000
        ])
    }

    // MARK: - Error Tracking

    func logError(_ error: Error, context: String? = nil) {
        var parameters: [String: Any] = [
            "error": error.localizedDescription,
            "error_type": String(describing: type(of: error))
        ]

        if let context = context {
            parameters["context"] = context
        }

        logEvent(.crashOccurred, parameters: parameters)
    }

    // MARK: - Backend Communication

    private func sendToBackend(event: String, parameters: [String: Any]) {
        // TODO: Implement actual backend communication
        // This would send events to your analytics service

        // Example structure for backend payload:
        let payload: [String: Any] = [
            "event": event,
            "properties": parameters,
            "timestamp": Date().timeIntervalSince1970
        ]

        // In production, this would be an async network request
        Task {
            await sendEventToServer(payload)
        }
    }

    private func sendEventToServer(_ payload: [String: Any]) async {
        // Placeholder for actual implementation
        // This would use URLSession to send to analytics endpoint
    }
}

// MARK: - Analytics Helper Extensions

extension AnalyticsService {
    // Convenience methods for common events

    func trackLogin(success: Bool, method: String = "email") {
        logEvent(success ? .loginSuccess : .loginFailure, parameters: [
            "method": method
        ])
    }

    func trackMessageSent(chatId: String, messageType: Message.MessageType) {
        logEvent(.messageSent, parameters: [
            "chat_id": chatId,
            "message_type": messageType.rawValue
        ])
    }

    func trackMessageReaction(messageId: String, reaction: String) {
        logEvent(.messageReaction, parameters: [
            "message_id": messageId,
            "reaction": reaction
        ])
    }

    func trackChatOpened(chatId: String, chatType: Chat.ChatType) {
        logEvent(.chatOpened, parameters: [
            "chat_id": chatId,
            "chat_type": chatType.rawValue
        ])
    }

    func trackMediaShared(type: Message.MessageType, size: Int64) {
        let event: AnalyticsEvent = {
            switch type {
            case .image: return .imageShared
            case .video: return .videoShared
            case .audio: return .voiceMessageSent
            case .file: return .fileShared
            default: return .messageSent
            }
        }()

        logEvent(event, parameters: [
            "media_type": type.rawValue,
            "size_bytes": size
        ])
    }
}
