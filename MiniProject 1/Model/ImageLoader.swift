//
//  ImageLoader.swift
//  MiniProject 1
//

import UIKit

/// Downloads thumbnails and keeps the decoded results in memory so scrolling
/// back over a row does not hit the network again.
actor ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession = .shared

    func image(for url: URL) async throws -> UIImage? {
        let key = url as NSURL

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let (data, _) = try await session.data(from: url)

        guard let image = UIImage(data: data) else { return nil }

        cache.setObject(image, forKey: key)
        return image
    }
}
