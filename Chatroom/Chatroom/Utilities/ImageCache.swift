//
//  ImageCache.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Create cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure cache
        cache.countLimit = 100 // Maximum 100 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    // MARK: - Memory Cache

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)

        // Also save to disk
        Task {
            await saveToDisk(image, forKey: key)
        }
    }

    func image(forKey key: String) -> UIImage? {
        // Check memory cache first
        if let image = cache.object(forKey: key as NSString) {
            return image
        }

        // Check disk cache
        if let image = loadFromDisk(forKey: key) {
            cache.setObject(image, forKey: key as NSString)
            return image
        }

        return nil
    }

    @objc private func clearMemoryCache() {
        cache.removeAllObjects()
    }

    // MARK: - Disk Cache

    private func saveToDisk(_ image: UIImage, forKey key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        try? data.write(to: fileURL)
    }

    private func loadFromDisk(forKey key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        return UIImage(data: data)
    }

    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)

        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Cache Management

    func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }

    func cacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }

            totalSize += Int64(fileSize)
        }

        return totalSize
    }
}

// MARK: - Cached Async Image

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }

        isLoading = true

        // Check cache first
        if let cachedImage = ImageCache.shared.image(forKey: url.absoluteString) {
            self.image = cachedImage
            isLoading = false
            return
        }

        // Download image
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let downloadedImage = UIImage(data: data) {
                ImageCache.shared.setImage(downloadedImage, forKey: url.absoluteString)
                await MainActor.run {
                    self.image = downloadedImage
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { image in image.resizable() },
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}

// MARK: - String Extension for MD5

extension String {
    var md5Hash: String {
        guard let data = self.data(using: .utf8) else { return self }
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
}
