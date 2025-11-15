//
//  CreateGroupView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateGroupViewModel()

    var body: some View {
        NavigationView {
            Form {
                // Group Info Section
                Section("Group Information") {
                    TextField("Group Name", text: $viewModel.groupName)

                    HStack {
                        Text("Group Icon")
                        Spacer()
                        Button(action: {
                            viewModel.showingImagePicker = true
                        }) {
                            if let iconURL = viewModel.groupIconURL {
                                AsyncImage(url: URL(string: iconURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    groupIconPlaceholder
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                groupIconPlaceholder
                            }
                        }
                    }
                }

                // Members Section
                Section {
                    HStack {
                        Text("Members")
                        Spacer()
                        Text("\(viewModel.selectedUsers.count)")
                            .foregroundColor(.secondary)
                    }

                    ForEach(viewModel.selectedUsers) { user in
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(user.displayName.prefix(1))
                                        .foregroundColor(.blue)
                                )

                            Text(user.displayName)

                            Spacer()

                            Button(action: {
                                viewModel.removeUser(user)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    Button(action: {
                        viewModel.showingUserPicker = true
                    }) {
                        Label("Add Members", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Members (\(viewModel.selectedUsers.count))")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            if await viewModel.createGroup() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canCreateGroup || viewModel.isLoading)
                }

                ToolbarItem(placement: .principal) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingUserPicker) {
                UserPickerView(selectedUsers: $viewModel.selectedUsers)
            }
            .sheet(isPresented: $viewModel.showingImagePicker) {
                ImagePicker(imageURL: $viewModel.groupIconURL)
            }
        }
    }

    private var groupIconPlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "person.3.fill")
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Create Group ViewModel

@MainActor
class CreateGroupViewModel: ObservableObject {
    @Published var groupName = ""
    @Published var groupIconURL: String?
    @Published var selectedUsers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingUserPicker = false
    @Published var showingImagePicker = false

    private let apiClient: APIClient
    private let chatRepository: ChatRepository

    var canCreateGroup: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty && selectedUsers.count >= 2
    }

    init(apiClient: APIClient = .shared, chatRepository: ChatRepository = ChatRepository()) {
        self.apiClient = apiClient
        self.chatRepository = chatRepository
    }

    func createGroup() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let participantIds = selectedUsers.map { $0.id }
            let newChat = try await apiClient.createChat(
                participantIds: participantIds,
                type: .group,
                name: groupName
            )

            chatRepository.saveChat(newChat)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func removeUser(_ user: User) {
        selectedUsers.removeAll { $0.id == user.id }
    }
}

// MARK: - User Picker View

struct UserPickerView: View {
    @Binding var selectedUsers: [User]
    @StateObject private var viewModel = UserPickerViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search users", text: $viewModel.searchQuery)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(viewModel.users) { user in
                            UserRowView(
                                user: user,
                                isSelected: selectedUsers.contains(where: { $0.id == user.id })
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleUser(user)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadUsers()
            }
            .onChange(of: viewModel.searchQuery) { _ in
                Task {
                    await viewModel.searchUsers()
                }
            }
        }
    }

    private func toggleUser(_ user: User) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }
}

struct UserRowView: View {
    let user: User
    let isSelected: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.displayName.prefix(1))
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.body)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - User Picker ViewModel

@MainActor
class UserPickerViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var searchQuery = ""
    @Published var isLoading = false

    private let apiClient: APIClient
    private let userRepository: UserRepository

    init(apiClient: APIClient = .shared, userRepository: UserRepository = UserRepository()) {
        self.apiClient = apiClient
        self.userRepository = userRepository
    }

    func loadUsers() async {
        isLoading = true

        do {
            users = try await apiClient.fetchUsers()
            userRepository.saveUsers(users)
            isLoading = false
        } catch {
            // Fall back to offline data
            users = userRepository.fetchAllUsers()
            isLoading = false
        }
    }

    func searchUsers() async {
        guard !searchQuery.isEmpty else {
            await loadUsers()
            return
        }

        isLoading = true

        do {
            users = try await apiClient.fetchUsers(search: searchQuery)
            isLoading = false
        } catch {
            // Fall back to local search
            users = userRepository.searchUsers(query: searchQuery)
            isLoading = false
        }
    }
}

#Preview {
    CreateGroupView()
}
