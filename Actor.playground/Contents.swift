import SwiftUI

// Image download cache
actor ImageDownloader {
    private var cache: [URL: Image] = [:]

    func image(from url: URL) async throws -> Image? {
        if let cache = cache[url] {
            return cache
        }

        let image = try await downloadImage(from: url)

        cache[url] = image
        return image
    }

    private func downloadImage(from url: URL) async throws -> Image {
        return Image("test")
    }
}
