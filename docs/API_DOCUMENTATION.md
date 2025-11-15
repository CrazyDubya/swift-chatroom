# API Documentation

## Overview

This document describes the REST API and WebSocket endpoints required for the Chatroom application backend.

**Base URL**: `https://api.chatroom.example.com/v1`

**Authentication**: Bearer token in Authorization header

## Authentication

### Register User

Creates a new user account.

**Endpoint**: `POST /auth/register`

**Request Body**:
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "display_name": "John Doe"
}
```

**Response** (201 Created):
```json
{
  "user": {
    "id": "user_123",
    "username": "johndoe",
    "email": "john@example.com",
    "display_name": "John Doe",
    "avatar_url": null,
    "created_at": "2025-11-15T10:00:00Z",
    "last_seen": null
  },
  "token": "eyJhbGc...",
  "refresh_token": "eyJhbGc..."
}
```

**Errors**:
- `400 Bad Request`: Invalid input data
- `409 Conflict`: Username or email already exists

---

### Login

Authenticates a user and returns tokens.

**Endpoint**: `POST /auth/login`

**Request Body**:
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response** (200 OK):
```json
{
  "user": {
    "id": "user_123",
    "username": "johndoe",
    "email": "john@example.com",
    "display_name": "John Doe",
    "avatar_url": "https://cdn.example.com/avatars/user_123.jpg",
    "created_at": "2025-11-15T10:00:00Z",
    "last_seen": "2025-11-15T10:30:00Z"
  },
  "token": "eyJhbGc...",
  "refresh_token": "eyJhbGc..."
}
```

**Errors**:
- `401 Unauthorized`: Invalid credentials

---

## Users

### Get Users

Search or list users.

**Endpoint**: `GET /users`

**Query Parameters**:
- `search` (optional): Search query for username or display name

**Example**: `GET /users?search=john`

**Response** (200 OK):
```json
[
  {
    "id": "user_123",
    "username": "johndoe",
    "email": "john@example.com",
    "display_name": "John Doe",
    "avatar_url": "https://cdn.example.com/avatars/user_123.jpg",
    "created_at": "2025-11-15T10:00:00Z",
    "last_seen": "2025-11-15T10:30:00Z"
  }
]
```

**Authentication**: Required

---

### Get User by ID

Fetch details for a specific user.

**Endpoint**: `GET /users/:id`

**Response** (200 OK):
```json
{
  "id": "user_123",
  "username": "johndoe",
  "email": "john@example.com",
  "display_name": "John Doe",
  "avatar_url": "https://cdn.example.com/avatars/user_123.jpg",
  "created_at": "2025-11-15T10:00:00Z",
  "last_seen": "2025-11-15T10:30:00Z"
}
```

**Errors**:
- `404 Not Found`: User does not exist

**Authentication**: Required

---

## Chats

### Get Chats

Fetch all chats for the authenticated user.

**Endpoint**: `GET /chats`

**Response** (200 OK):
```json
[
  {
    "id": "chat_456",
    "name": null,
    "participants": [
      {
        "id": "user_123",
        "username": "johndoe",
        "display_name": "John Doe",
        "avatar_url": "https://cdn.example.com/avatars/user_123.jpg"
      },
      {
        "id": "user_789",
        "username": "janesmith",
        "display_name": "Jane Smith",
        "avatar_url": "https://cdn.example.com/avatars/user_789.jpg"
      }
    ],
    "type": "direct",
    "last_message": {
      "id": "msg_999",
      "chat_id": "chat_456",
      "sender_id": "user_789",
      "sender_name": "Jane Smith",
      "content": "Hey! How are you?",
      "type": "text",
      "timestamp": "2025-11-15T11:00:00Z",
      "is_read": false
    },
    "unread_count": 3,
    "created_at": "2025-11-15T09:00:00Z",
    "updated_at": "2025-11-15T11:00:00Z"
  }
]
```

**Authentication**: Required

---

### Create Chat

Create a new chat (direct or group).

**Endpoint**: `POST /chats`

**Request Body**:
```json
{
  "participant_ids": ["user_789"],
  "type": "direct",
  "name": null
}
```

For group chats:
```json
{
  "participant_ids": ["user_789", "user_101", "user_202"],
  "type": "group",
  "name": "Project Team"
}
```

**Response** (201 Created):
```json
{
  "id": "chat_456",
  "name": null,
  "participants": [
    {
      "id": "user_123",
      "username": "johndoe",
      "display_name": "John Doe",
      "avatar_url": "https://cdn.example.com/avatars/user_123.jpg"
    },
    {
      "id": "user_789",
      "username": "janesmith",
      "display_name": "Jane Smith",
      "avatar_url": "https://cdn.example.com/avatars/user_789.jpg"
    }
  ],
  "type": "direct",
  "last_message": null,
  "unread_count": 0,
  "created_at": "2025-11-15T09:00:00Z",
  "updated_at": "2025-11-15T09:00:00Z"
}
```

**Errors**:
- `400 Bad Request`: Invalid participant IDs
- `409 Conflict`: Direct chat already exists

**Authentication**: Required

---

## Messages

### Get Messages

Fetch messages for a specific chat.

**Endpoint**: `GET /chats/:chatId/messages`

**Query Parameters**:
- `limit` (optional): Number of messages to return (default: 50)
- `before` (optional): Message ID to paginate before
- `after` (optional): Message ID to paginate after

**Example**: `GET /chats/chat_456/messages?limit=20`

**Response** (200 OK):
```json
[
  {
    "id": "msg_999",
    "chat_id": "chat_456",
    "sender_id": "user_789",
    "sender_name": "Jane Smith",
    "content": "Hey! How are you?",
    "type": "text",
    "media_url": null,
    "timestamp": "2025-11-15T11:00:00Z",
    "is_read": false,
    "delivered_at": "2025-11-15T11:00:01Z",
    "read_at": null
  },
  {
    "id": "msg_998",
    "chat_id": "chat_456",
    "sender_id": "user_123",
    "sender_name": "John Doe",
    "content": "I'm good! Thanks for asking.",
    "type": "text",
    "media_url": null,
    "timestamp": "2025-11-15T10:58:00Z",
    "is_read": true,
    "delivered_at": "2025-11-15T10:58:01Z",
    "read_at": "2025-11-15T10:59:00Z"
  }
]
```

**Authentication**: Required

---

### Send Message

Send a new message to a chat.

**Endpoint**: `POST /chats/:chatId/messages`

**Request Body**:
```json
{
  "chat_id": "chat_456",
  "content": "Hello, world!",
  "type": "text",
  "media_url": null
}
```

For media messages:
```json
{
  "chat_id": "chat_456",
  "content": "Check out this photo!",
  "type": "image",
  "media_url": "https://cdn.example.com/media/img_123.jpg"
}
```

**Message Types**:
- `text`: Plain text message
- `image`: Image with optional caption
- `video`: Video with optional caption
- `audio`: Audio message
- `file`: File attachment
- `system`: System notification (server-generated only)

**Response** (201 Created):
```json
{
  "id": "msg_1000",
  "chat_id": "chat_456",
  "sender_id": "user_123",
  "sender_name": "John Doe",
  "content": "Hello, world!",
  "type": "text",
  "media_url": null,
  "timestamp": "2025-11-15T11:05:00Z",
  "is_read": false,
  "delivered_at": null,
  "read_at": null
}
```

**Authentication**: Required

---

### Mark Message as Read

Mark a message as read.

**Endpoint**: `PUT /messages/:messageId/read`

**Response** (200 OK):
```json
{}
```

**Authentication**: Required

---

## WebSocket

### Connection

Establish WebSocket connection for real-time updates.

**Endpoint**: `WS /ws?token={auth_token}`

**Authentication**: Token in query parameter

**Connection Example**:
```
wss://api.chatroom.example.com/v1/ws?token=eyJhbGc...
```

### Message Format

All WebSocket messages are JSON-encoded.

#### Incoming Message Event

Server sends new messages to clients:

```json
{
  "type": "message",
  "data": {
    "id": "msg_1001",
    "chat_id": "chat_456",
    "sender_id": "user_789",
    "sender_name": "Jane Smith",
    "content": "Real-time message!",
    "type": "text",
    "media_url": null,
    "timestamp": "2025-11-15T11:10:00Z",
    "is_read": false,
    "delivered_at": "2025-11-15T11:10:01Z",
    "read_at": null
  }
}
```

#### Typing Indicator

User is typing notification:

```json
{
  "type": "typing",
  "data": {
    "chat_id": "chat_456",
    "user_id": "user_789",
    "user_name": "Jane Smith",
    "is_typing": true
  }
}
```

#### Message Read Receipt

Message was read notification:

```json
{
  "type": "read_receipt",
  "data": {
    "message_id": "msg_999",
    "chat_id": "chat_456",
    "user_id": "user_123",
    "read_at": "2025-11-15T11:15:00Z"
  }
}
```

#### Presence Update

User online/offline status:

```json
{
  "type": "presence",
  "data": {
    "user_id": "user_789",
    "status": "online",
    "last_seen": "2025-11-15T11:20:00Z"
  }
}
```

### Client Events

#### Send Typing Indicator

```json
{
  "type": "typing",
  "chat_id": "chat_456",
  "is_typing": true
}
```

#### Send Presence Update

```json
{
  "type": "presence",
  "status": "online"
}
```

### Connection Management

#### Heartbeat (Ping/Pong)

Client should send ping every 30 seconds:
```json
{
  "type": "ping"
}
```

Server responds with:
```json
{
  "type": "pong"
}
```

#### Reconnection

If connection drops:
1. Wait 2 seconds
2. Attempt reconnection
3. Use exponential backoff up to 60 seconds
4. Fetch missed messages via REST API

---

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "The email field is required",
    "details": {
      "field": "email",
      "constraint": "required"
    }
  }
}
```

### Common Error Codes

- `INVALID_INPUT`: Request validation failed
- `UNAUTHORIZED`: Authentication required or invalid
- `FORBIDDEN`: Authenticated but insufficient permissions
- `NOT_FOUND`: Resource does not exist
- `CONFLICT`: Resource already exists
- `RATE_LIMITED`: Too many requests
- `INTERNAL_ERROR`: Server error

---

## Rate Limiting

- **Authentication**: 5 requests per minute per IP
- **API Endpoints**: 100 requests per minute per user
- **WebSocket Messages**: 60 messages per minute per user

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1700051400
```

---

## Pagination

List endpoints support pagination:

**Query Parameters**:
- `limit`: Number of items (max 100, default 50)
- `cursor`: Pagination cursor from previous response

**Response Headers**:
```
X-Total-Count: 250
X-Next-Cursor: eyJpZCI6MTIzfQ==
```

**Example**:
```
GET /chats/chat_456/messages?limit=20&cursor=eyJpZCI6MTIzfQ==
```

---

## Media Upload

### Upload Media

Upload media files before sending message.

**Endpoint**: `POST /media/upload`

**Request**: Multipart form data
- `file`: The media file
- `type`: Media type (image, video, audio, file)

**Response** (201 Created):
```json
{
  "url": "https://cdn.example.com/media/img_123.jpg",
  "type": "image",
  "size": 245632,
  "filename": "photo.jpg"
}
```

**Max File Sizes**:
- Images: 10 MB
- Videos: 100 MB
- Audio: 20 MB
- Files: 50 MB

**Authentication**: Required

---

## Best Practices

1. **Authentication**: Include Bearer token in all requests
2. **Dates**: Use ISO8601 format (UTC timezone)
3. **Pagination**: Use cursor-based pagination for lists
4. **WebSocket**: Implement reconnection logic
5. **Error Handling**: Handle all documented error codes
6. **Rate Limiting**: Implement exponential backoff
7. **Offline Support**: Cache data locally, sync when online

---

## Versioning

API version is in the URL path: `/v1/`

Major version changes will be announced 6 months in advance.

---

## Support

For API issues or questions:
- Email: api-support@chatroom.example.com
- Documentation: https://docs.chatroom.example.com
