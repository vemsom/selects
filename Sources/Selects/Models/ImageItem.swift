import Foundation

struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    let urls: [URL]
    var rating: Int = 0

    var primaryURL: URL { urls[0] }
    var rawURL: URL? {
        urls.first { imageExtensions.raw.contains($0.pathExtension.lowercased()) }
    }
    var displayName: String { primaryURL.lastPathComponent }
    var baseName: String { primaryURL.deletingPathExtension().lastPathComponent }

    var isRAW: Bool {
        urls.contains { imageExtensions.raw.contains($0.pathExtension.lowercased()) }
    }

    static func groupFiles(_ urls: [URL]) -> [ImageItem] {
        Dictionary(grouping: urls) { url in
            url.deletingPathExtension().lastPathComponent
        }
        .map { _, groupURLs in
            let sorted = groupURLs.sorted { lhs, rhs in
                let lhsIsStandard = imageExtensions.standard.contains(lhs.pathExtension.lowercased())
                let rhsIsStandard = imageExtensions.standard.contains(rhs.pathExtension.lowercased())
                if lhsIsStandard != rhsIsStandard { return lhsIsStandard }
                return lhs.lastPathComponent < rhs.lastPathComponent
            }
            return ImageItem(urls: sorted)
        }
    }
}

enum imageExtensions {
    static let standard: Set<String> = ["jpg", "jpeg", "png", "tiff", "tif", "heic", "heif", "bmp"]
    static let raw: Set<String> = ["rw2", "dng", "cr3", "cr2", "nef", "arw", "orf", "raf", "srw"]
    static let all: Set<String> = standard.union(raw)
}
