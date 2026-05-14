import Foundation

enum FileOperations {
    static func trashFiles(at urls: [URL]) throws {
        let trashDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash")

        try FileManager.default.createDirectory(at: trashDir, withIntermediateDirectories: true)

        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            var destination = trashDir.appendingPathComponent(url.lastPathComponent)
            var counter = 1
            while FileManager.default.fileExists(atPath: destination.path) {
                let name = url.deletingPathExtension().lastPathComponent
                let ext = url.pathExtension
                destination = trashDir.appendingPathComponent("\(name) \(counter).\(ext)")
                counter += 1
            }

            try FileManager.default.moveItem(at: url, to: destination)
        }
    }

    static func isImageFile(_ url: URL) -> Bool {
        imageExtensions.all.contains(url.pathExtension.lowercased())
    }
}
