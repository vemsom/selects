import AppKit

private struct CacheKey: Hashable {
    let url: URL
    let pixelSize: Int
}

final class ImageLoader: @unchecked Sendable {
    static let shared = ImageLoader()

    private var cache: [CacheKey: NSImage] = [:]
    private let lock = NSLock()

    private init() {}

    func loadImage(from url: URL, maxPixelSize: Int = 2000) -> NSImage? {
        let key = CacheKey(url: url, pixelSize: maxPixelSize)

        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let image = decodeImage(from: url, maxPixelSize: maxPixelSize) else {
            return nil
        }

        lock.lock()
        cache[key] = image
        lock.unlock()
        return image
    }

    private func decodeImage(from url: URL, maxPixelSize: Int) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: .zero)
    }

    func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}
