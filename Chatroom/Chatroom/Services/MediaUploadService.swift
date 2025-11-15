//
//  MediaUploadService.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import UIKit

enum MediaType: String {
    case image
    case video
    case audio
    case file
}

struct MediaUploadResponse: Codable {
    let url: String
    let type: String
    let size: Int
    let filename: String
}

class MediaUploadService {
    static let shared = MediaUploadService()

    private let baseURL = "https://api.chatroom.example.com/v1"
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Upload Methods

    func uploadImage(_ image: UIImage, type: MediaType = .image) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MediaUploadError.invalidImage
        }

        return try await uploadMedia(
            data: imageData,
            filename: "image_\(UUID().uuidString).jpg",
            mimeType: "image/jpeg",
            type: type
        )
    }

    func uploadVideo(from url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        let filename = url.lastPathComponent

        return try await uploadMedia(
            data: data,
            filename: filename,
            mimeType: "video/mp4",
            type: .video
        )
    }

    func uploadFile(from url: URL, type: MediaType = .file) async throws -> String {
        let data = try Data(contentsOf: url)
        let filename = url.lastPathComponent
        let mimeType = getMimeType(for: url)

        return try await uploadMedia(
            data: data,
            filename: filename,
            mimeType: mimeType,
            type: type
        )
    }

    // MARK: - Private Methods

    private func uploadMedia(
        data: Data,
        filename: String,
        mimeType: String,
        type: MediaType
    ) async throws -> String {
        guard let url = URL(string: baseURL + "/media/upload") else {
            throw MediaUploadError.invalidURL
        }

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add authentication token
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()

        // Add type field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(type.rawValue)\r\n".data(using: .utf8)!)

        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Upload
        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw MediaUploadError.uploadFailed
        }

        let decoder = JSONDecoder()
        let uploadResponse = try decoder.decode(MediaUploadResponse.self, from: responseData)

        return uploadResponse.url
    }

    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "mp3":
            return "audio/mpeg"
        case "m4a":
            return "audio/mp4"
        case "pdf":
            return "application/pdf"
        case "doc", "docx":
            return "application/msword"
        default:
            return "application/octet-stream"
        }
    }

    // MARK: - Image Compression

    func compressImage(_ image: UIImage, maxSize: Int = 1024 * 1024) -> Data? {
        var compression: CGFloat = 0.9
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSize && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        return imageData
    }

    func resizeImage(_ image: UIImage, maxWidth: CGFloat = 1024) -> UIImage {
        let ratio = maxWidth / image.size.width
        let newSize = CGSize(width: maxWidth, height: image.size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Errors

enum MediaUploadError: Error, LocalizedError {
    case invalidImage
    case invalidURL
    case uploadFailed
    case fileTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .invalidURL:
            return "Invalid upload URL"
        case .uploadFailed:
            return "Upload failed"
        case .fileTooLarge:
            return "File is too large"
        }
    }
}
