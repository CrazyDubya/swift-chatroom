//
//  AuthViewModel.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
        checkAuthenticationStatus()
    }

    // MARK: - Authentication Methods

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.login(email: email, password: password)
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func register(username: String, email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.register(
                username: username,
                email: email,
                password: password,
                displayName: displayName
            )
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func logout() {
        authService.logout()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Private Methods

    private func checkAuthenticationStatus() {
        if authService.isAuthenticated {
            isAuthenticated = true
            // Load current user from stored token
            Task {
                await loadCurrentUser()
            }
        }
    }

    private func loadCurrentUser() async {
        do {
            let user = try await authService.getCurrentUser()
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
            currentUser = nil
        }
    }
}
