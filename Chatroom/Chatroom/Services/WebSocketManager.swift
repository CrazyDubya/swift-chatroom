//
//  WebSocketManager.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import Combine

class WebSocketManager: NSObject {
    static let shared = WebSocketManager()

    private var webSocketTask: URLSessionWebSocketTask?
    private let messageSubject = PassthroughSubject<Message, Never>()

    var messagePublisher: AnyPublisher<Message, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    private var isConnected = false
    private let baseURL = "wss://api.chatroom.example.com/v1/ws"

    private override init() {
        super.init()
    }

    // MARK: - Connection Methods

    func connect() {
        guard let token = AuthService.shared.authToken else {
            print("WebSocket: No auth token available")
            return
        }

        guard let url = URL(string: "\(baseURL)?token=\(token)") else {
            print("WebSocket: Invalid URL")
            return
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        isConnected = true
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    // MARK: - Message Handling

    func sendMessage(_ message: Message) {
        guard isConnected else {
            print("WebSocket: Not connected")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(message)

            let messageString = String(data: data, encoding: .utf8)!
            let message = URLSessionWebSocketTask.Message.string(messageString)

            webSocketTask?.send(message) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        } catch {
            print("WebSocket encoding error: \(error)")
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleReceivedMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleReceivedMessage(text)
                    }
                @unknown default:
                    break
                }

                // Continue listening for messages
                self?.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.handleDisconnection()
            }
        }
    }

    private func handleReceivedMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let message = try decoder.decode(Message.self, from: data)
            messageSubject.send(message)
        } catch {
            print("WebSocket decoding error: \(error)")
        }
    }

    private func handleDisconnection() {
        isConnected = false

        // Attempt to reconnect after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.connect()
        }
    }

    // MARK: - Ping/Pong

    private func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("WebSocket ping error: \(error)")
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket: Connected")
        isConnected = true

        // Start periodic ping
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket: Disconnected")
        handleDisconnection()
    }
}
