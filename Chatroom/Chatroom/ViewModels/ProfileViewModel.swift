//
//  ProfileViewModel.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var username = ""
    @Published var email = ""
    @Published var avatarURL: String?

    @Published var pushNotificationsEnabled = true
    @Published var showMessagePreview = true
    @Published var readReceiptsEnabled = true
    @Published var showOnlineStatus = true
    @Published var showLastSeen = true

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasChanges = false
    @Published var cacheSize = "0 KB"

    private let apiClient: APIClient
    private let syncService: SyncService
    private var originalUser: User?

    init(apiClient: APIClient = .shared, syncService: SyncService = .shared) {
        self.apiClient = apiClient
        self.syncService = syncService
        updateCacheSize()
    }

    // MARK: - Profile Methods

    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.getCurrentUser()

            displayName = user.displayName
            username = user.username
            email = user.email
            avatarURL = user.avatarURL
            originalUser = user

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func saveProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            // TODO: Update profile on API
            // let updatedUser = try await apiClient.updateProfile(...)

            hasChanges = false
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
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
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
