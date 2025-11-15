# Architecture Documentation

## Overview

Chatroom follows a clean architecture approach using the MVVM (Model-View-ViewModel) pattern with SwiftUI. This document outlines the architectural decisions, patterns, and best practices used throughout the application.

## Core Principles

1. **Separation of Concerns**: Each layer has a distinct responsibility
2. **Dependency Injection**: Dependencies are passed via initializers
3. **Testability**: All components can be tested in isolation
4. **Reactive Programming**: Using Combine for data flow
5. **Modern Swift**: Leveraging async/await for concurrency

## Layer Architecture

### 1. Models Layer

**Purpose**: Define data structures and business entities

**Components**:
- `User.swift`: User profile and authentication models
- `Message.swift`: Message data and types
- `Chat.swift`: Chat/conversation models

**Characteristics**:
- Pure Swift structs
- Codable for JSON serialization
- Identifiable for SwiftUI lists
- Equatable for comparison
- No business logic

**Example**:
```swift
struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String
    var email: String
    // ...
}
```

### 2. Views Layer

**Purpose**: SwiftUI views for UI presentation

**Components**:
- `LoginView.swift`: Authentication interface
- `ChatListView.swift`: List of conversations
- `ChatDetailView.swift`: Message thread
- `MessageRow.swift`: Individual message UI

**Characteristics**:
- Declarative SwiftUI syntax
- @EnvironmentObject for shared state
- @StateObject for view-owned state
- No direct API calls
- Minimal business logic

**Data Flow**:
```
User Input → View → ViewModel → Service → API
                ↑
           State Updates
```

### 3. ViewModels Layer

**Purpose**: Business logic and state management

**Components**:
- `AuthViewModel.swift`: Authentication state and logic
- `ChatViewModel.swift`: Chat and messaging logic

**Characteristics**:
- @MainActor for UI updates
- @Published properties for reactive updates
- Async/await for asynchronous operations
- ObservableObject protocol
- No UI code

**Responsibilities**:
- Manage UI state
- Coordinate service calls
- Transform data for views
- Handle user actions
- Error handling

**Example**:
```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    func login(email: String, password: String) async {
        // Business logic
    }
}
```

### 4. Services Layer

**Purpose**: External communication and data management

**Components**:
- `APIClient.swift`: REST API communication
- `AuthService.swift`: Authentication management
- `WebSocketManager.swift`: Real-time messaging

**Characteristics**:
- Singleton pattern for shared instances
- Generic request methods
- Error handling
- Token management
- No UI dependencies

**APIClient Design**:
```swift
class APIClient {
    static let shared = APIClient()

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        // Generic networking
    }
}
```

## Data Flow

### Authentication Flow

```
LoginView
    ↓ (user taps login)
AuthViewModel.login()
    ↓
AuthService.login()
    ↓ (HTTP POST)
Backend API
    ↓ (returns token + user)
AuthService (stores token in Keychain)
    ↓
AuthViewModel.isAuthenticated = true
    ↓
ContentView shows ChatListView
```

### Messaging Flow

```
ChatDetailView
    ↓ (user sends message)
ChatViewModel.sendMessage()
    ↓
APIClient.sendMessage()
    ↓ (HTTP POST)
Backend API
    ↓ (WebSocket broadcast)
WebSocketManager receives message
    ↓ (Combine publisher)
ChatViewModel.handleNewMessage()
    ↓
View updates with new message
```

## State Management

### View State
- Managed by @State for local view state
- @StateObject for view-owned ViewModels
- @FocusState for keyboard focus

### Shared State
- @EnvironmentObject for app-wide state
- Singletons for services (APIClient, AuthService)

### Persistence
- Keychain for sensitive data (tokens)
- UserDefaults for preferences (future)
- Core Data for local caching (Phase 1)

## Networking

### REST API

**APIClient** provides a generic request method:

```swift
func request<T: Decodable>(
    endpoint: String,
    method: String,
    body: Encodable?
) async throws -> T
```

**Features**:
- Automatic token injection
- JSON encoding/decoding
- Error handling
- ISO8601 date parsing

### WebSocket

**WebSocketManager** handles real-time updates:

```swift
class WebSocketManager {
    var messagePublisher: AnyPublisher<Message, Never>

    func connect()
    func disconnect()
    func sendMessage(_ message: Message)
}
```

**Features**:
- Automatic reconnection
- Ping/pong heartbeat
- Message encoding/decoding
- Combine integration

## Security

### Token Storage

Tokens are stored securely in the iOS Keychain:

```swift
class KeychainHelper {
    static func save(key: String, value: String)
    static func get(key: String) -> String?
    static func delete(key: String)
}
```

### Authentication

All authenticated requests include the bearer token:

```swift
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

## Error Handling

### API Errors

```swift
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)
}
```

### ViewModel Error Handling

```swift
@Published var errorMessage: String?

do {
    let result = try await service.someMethod()
} catch {
    errorMessage = error.localizedDescription
}
```

## Concurrency

### Async/Await

Modern Swift concurrency for asynchronous operations:

```swift
func loadChats() async {
    isLoading = true
    do {
        chats = try await apiClient.fetchChats()
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

### @MainActor

ViewModels use @MainActor to ensure UI updates on main thread:

```swift
@MainActor
class ChatViewModel: ObservableObject {
    // All methods run on main thread
}
```

## Dependency Injection

### Constructor Injection

ViewModels accept dependencies via initializers:

```swift
class ChatViewModel: ObservableObject {
    private let apiClient: APIClient
    private let webSocketManager: WebSocketManager

    init(
        apiClient: APIClient = .shared,
        webSocketManager: WebSocketManager = .shared
    ) {
        self.apiClient = apiClient
        self.webSocketManager = webSocketManager
    }
}
```

**Benefits**:
- Easy testing with mock services
- Flexible configuration
- Clear dependencies

## Testing Strategy

### Unit Testing

ViewModels can be tested with mock services:

```swift
class MockAPIClient: APIClient {
    var mockChats: [Chat] = []

    override func fetchChats() async throws -> [Chat] {
        return mockChats
    }
}

// Test
func testLoadChats() async {
    let mockClient = MockAPIClient()
    mockClient.mockChats = [/* test data */]

    let viewModel = ChatViewModel(apiClient: mockClient)
    await viewModel.loadChats()

    XCTAssertEqual(viewModel.chats.count, 1)
}
```

### Integration Testing

Test complete flows with test backend

### UI Testing

SwiftUI previews for visual testing

## Performance Considerations

### Lazy Loading

```swift
LazyVStack {
    ForEach(messages) { message in
        MessageRow(message: message)
    }
}
```

### Efficient Updates

Use Identifiable for efficient list updates:

```swift
struct Message: Identifiable {
    let id: String
    // ...
}
```

### Memory Management

- Weak references in closures
- Proper cancellable cleanup
- Avoid retain cycles

## Future Improvements

### Phase 1
- Core Data integration for offline support
- Image caching layer
- Background refresh

### Phase 2
- Analytics service layer
- Crash reporting integration
- A/B testing framework

### Phase 3
- Modular architecture
- Feature flags
- Plugin system

## Conventions

### Naming
- ViewModels: `{Feature}ViewModel`
- Services: `{Feature}Service`
- Views: `{Feature}View`

### File Organization
- Group by feature, then by type
- Keep files under 400 lines
- One type per file

### Code Style
- SwiftLint for consistency
- Follow Apple's Swift style guide
- Use type inference where clear

## References

- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Clean Architecture in iOS](https://www.kodeco.com/8458-getting-started-with-clean-architecture)
