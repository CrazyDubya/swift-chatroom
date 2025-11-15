//
//  ProfileView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingLogoutAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProfileImageView(
                                imageURL: viewModel.avatarURL,
                                size: 100
                            )
                            .onTapGesture {
                                showingImagePicker = true
                            }

                            Button("Change Photo") {
                                showingImagePicker = true
                            }
                            .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // User Info Section
                Section("User Information") {
                    TextField("Display Name", text: $viewModel.displayName)
                    TextField("Username", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .disabled(true)
                }

                // Settings Section
                Section("Settings") {
                    Toggle("Push Notifications", isOn: $viewModel.pushNotificationsEnabled)
                    Toggle("Message Preview", isOn: $viewModel.showMessagePreview)
                    Toggle("Read Receipts", isOn: $viewModel.readReceiptsEnabled)
                }

                // Privacy Section
                Section("Privacy") {
                    Toggle("Show Online Status", isOn: $viewModel.showOnlineStatus)
                    Toggle("Show Last Seen", isOn: $viewModel.showLastSeen)
                }

                // Storage Section
                Section("Storage") {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(viewModel.cacheSize)
                            .foregroundColor(.secondary)
                    }

                    Button("Clear Cache") {
                        viewModel.clearCache()
                    }
                    .foregroundColor(.red)
                }

                // Account Section
                Section {
                    Button("Save Changes") {
                        Task {
                            await viewModel.saveProfile()
                        }
                    }
                    .disabled(!viewModel.hasChanges || viewModel.isLoading)

                    Button("Logout") {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageURL: $viewModel.avatarURL)
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
            .task {
                await viewModel.loadProfile()
            }
        }
    }
}

// MARK: - Profile Image View

struct ProfileImageView: View {
    let imageURL: String?
    let size: CGFloat

    var body: some View {
        if let urlString = imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholderView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.5)
                    .foregroundColor(.blue)
            )
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageURL: String?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }

                    if let image = image as? UIImage {
                        // Upload image and get URL
                        Task {
                            await self.uploadImage(image)
                        }
                    }
                }
            }
        }

        private func uploadImage(_ image: UIImage) async {
            do {
                let imageURL = try await MediaUploadService.shared.uploadImage(image, type: .image)
                await MainActor.run {
                    parent.imageURL = imageURL
                }
            } catch {
                print("Failed to upload image: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
