//
//  SearchView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search messages", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: viewModel.selectedFilter == .all,
                            action: { viewModel.selectedFilter = .all }
                        )

                        FilterChip(
                            title: "Images",
                            icon: "photo",
                            isSelected: viewModel.selectedFilter == .images,
                            action: { viewModel.selectedFilter = .images }
                        )

                        FilterChip(
                            title: "Videos",
                            icon: "video",
                            isSelected: viewModel.selectedFilter == .videos,
                            action: { viewModel.selectedFilter = .videos }
                        )

                        FilterChip(
                            title: "Files",
                            icon: "doc",
                            isSelected: viewModel.selectedFilter == .files,
                            action: { viewModel.selectedFilter = .files }
                        )

                        FilterChip(
                            title: "Links",
                            icon: "link",
                            isSelected: viewModel.selectedFilter == .links,
                            action: { viewModel.selectedFilter = .links }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)

                Divider()

                // Results
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    EmptySearchView()
                } else if viewModel.searchResults.isEmpty {
                    SearchPlaceholderView()
                } else {
                    List {
                        ForEach(viewModel.groupedResults.keys.sorted(by: >), id: \.self) { chatId in
                            if let chat = viewModel.chats.first(where: { $0.id == chatId }),
                               let messages = viewModel.groupedResults[chatId] {
                                Section(header: Text(chat.displayName)) {
                                    ForEach(messages) { message in
                                        SearchResultRow(message: message, query: viewModel.searchQuery)
                                            .onTapGesture {
                                                viewModel.selectMessage(message)
                                                dismiss()
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.searchQuery) { _ in
                Task {
                    await viewModel.performSearch()
                }
            }
            .task {
                await viewModel.loadChats()
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct SearchResultRow: View {
    let message: Message
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(message.senderName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(message.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(highlightedContent)
                .font(.body)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private var highlightedContent: AttributedString {
        var attributed = AttributedString(message.content)

        if let range = attributed.range(of: query, options: .caseInsensitive) {
            attributed[range].backgroundColor = .yellow.opacity(0.3)
        }

        return attributed
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Results Found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("Search Messages")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Find messages, photos, and more")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search ViewModel

enum SearchFilter {
    case all
    case images
    case videos
    case files
    case links
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Message] = []
    @Published var chats: [Chat] = []
    @Published var isSearching = false
    @Published var selectedFilter: SearchFilter = .all

    private let messageRepository = MessageRepository()
    private let chatRepository = ChatRepository()
    private var searchTask: Task<Void, Never>?

    var groupedResults: [String: [Message]] {
        Dictionary(grouping: searchResults) { $0.chatId }
    }

    func loadChats() async {
        chats = chatRepository.fetchAllChats()
    }

    func performSearch() async {
        searchTask?.cancel()

        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            // Small debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            guard !Task.isCancelled else { return }

            await MainActor.run {
                isSearching = true
            }

            // Search in all chats
            var allResults: [Message] = []

            for chat in chats {
                guard !Task.isCancelled else { break }

                let messages = messageRepository.fetchMessages(forChatId: chat.id)
                let filtered = messages.filter { message in
                    matchesFilter(message) &&
                    message.content.localizedCaseInsensitiveContains(searchQuery)
                }
                allResults.append(contentsOf: filtered)
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                searchResults = allResults.sorted { $0.timestamp > $1.timestamp }
                isSearching = false

                // Track search
                AnalyticsService.shared.logEvent(.searchPerformed, parameters: [
                    "query": searchQuery,
                    "results_count": allResults.count
                ])
            }
        }
    }

    private func matchesFilter(_ message: Message) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .images:
            return message.type == .image
        case .videos:
            return message.type == .video
        case .files:
            return message.type == .file
        case .links:
            return message.content.contains("http://") || message.content.contains("https://")
        }
    }

    func selectMessage(_ message: Message) {
        // Post notification to navigate to this message
        NotificationCenter.default.post(
            name: .didSelectSearchResult,
            object: nil,
            userInfo: [
                "chatId": message.chatId,
                "messageId": message.id
            ]
        )
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let didSelectSearchResult = Notification.Name("didSelectSearchResult")
}

#Preview {
    SearchView()
}
