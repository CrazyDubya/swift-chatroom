//
//  SettingsView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLogoutAlert = false
    @State private var showingClearCacheAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $viewModel.pushNotificationsEnabled)
                        .onChange(of: viewModel.pushNotificationsEnabled) { newValue in
                            if newValue {
                                Task {
                                    await viewModel.requestNotificationPermission()
                                }
                            }
                        }

                    Toggle("Message Preview", isOn: $viewModel.showMessagePreview)
                        .disabled(!viewModel.pushNotificationsEnabled)

                    Toggle("Sound", isOn: $viewModel.notificationSound)
                        .disabled(!viewModel.pushNotificationsEnabled)
                }

                // Chat Settings Section
                Section("Chat") {
                    Toggle("Read Receipts", isOn: $viewModel.readReceiptsEnabled)
                    Toggle("Typing Indicators", isOn: $viewModel.typingIndicatorsEnabled)
                    Toggle("Media Auto-Download", isOn: $viewModel.autoDownloadMedia)

                    Picker("Message Font Size", selection: $viewModel.messageFontSize) {
                        Text("Small").tag(MessageFontSize.small)
                        Text("Medium").tag(MessageFontSize.medium)
                        Text("Large").tag(MessageFontSize.large)
                    }
                }

                // Privacy Section
                Section("Privacy") {
                    Toggle("Show Online Status", isOn: $viewModel.showOnlineStatus)
                    Toggle("Show Last Seen", isOn: $viewModel.showLastSeen)
                    Toggle("Profile Photo Visible", isOn: $viewModel.profilePhotoVisible)
                }

                // Data & Storage Section
                Section("Data & Storage") {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(viewModel.cacheSize)
                            .foregroundColor(.secondary)
                    }

                    Button("Clear Cache") {
                        showingClearCacheAlert = true
                    }
                    .foregroundColor(.red)

                    Toggle("Save to Camera Roll", isOn: $viewModel.saveToPhotos)
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy Content")
                    }

                    NavigationLink("Terms of Service") {
                        Text("Terms of Service Content")
                    }
                }

                // Account Section
                Section {
                    Button("Logout") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearCache()
                }
            } message: {
                Text("This will clear all cached messages and media. Are you sure?")
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authViewModel.logout()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

// MARK: - Settings ViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var pushNotificationsEnabled = false
    @Published var showMessagePreview = true
    @Published var notificationSound = true

    @Published var readReceiptsEnabled = true
    @Published var typingIndicatorsEnabled = true
    @Published var autoDownloadMedia = true
    @Published var messageFontSize: MessageFontSize = .medium

    @Published var showOnlineStatus = true
    @Published var showLastSeen = true
    @Published var profilePhotoVisible = true

    @Published var saveToPhotos = false
    @Published var cacheSize = "0 KB"

    let appVersion = "1.0.0"

    private let notificationService: NotificationService
    private let syncService: SyncService

    init(
        notificationService: NotificationService = .shared,
        syncService: SyncService = .shared
    ) {
        self.notificationService = notificationService
        self.syncService = syncService

        loadSettings()
        updateCacheSize()
    }

    func loadSettings() {
        Task {
            let status = await notificationService.getPermissionStatus()
            pushNotificationsEnabled = status == .authorized
        }
    }

    func requestNotificationPermission() async {
        let granted = await notificationService.requestPermission()
        pushNotificationsEnabled = granted
    }

    func clearCache() {
        syncService.clearCache()
        updateCacheSize()
    }

    private func updateCacheSize() {
        let bytes = syncService.getCacheSize()
        cacheSize = formatBytes(bytes)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Supporting Types

enum MessageFontSize: String, CaseIterable {
    case small
    case medium
    case large

    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
