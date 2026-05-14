import Foundation

struct FolderItem: Identifiable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }

    static func loadChildren(from url: URL) -> [FolderItem] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .filter { $0.hasDirectoryPath }
            .map { FolderItem(url: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
