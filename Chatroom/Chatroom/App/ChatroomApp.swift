//
//  ChatroomApp.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

@main
struct ChatroomApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
