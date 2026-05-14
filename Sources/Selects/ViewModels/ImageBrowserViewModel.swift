import SwiftUI

@Observable
final class ImageBrowserViewModel {
    private(set) var images: [ImageItem] = []
    private(set) var currentIndex: Int = 0
    private(set) var currentFolder: URL?
    private(set) var canUndo = false

    private struct UndoEntry {
        let item: ImageItem
        let index: Int
    }
    private var undoStack: [UndoEntry] = []

    var currentImage: ImageItem? {
        guard images.indices.contains(currentIndex) else { return nil }
        return images[currentIndex]
    }

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Välj en mapp med bilder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadFolder(url)
    }

    func loadFolder(_ url: URL) {
        currentFolder = url
        UserDefaults.standard.set(url.path, forKey: "lastFolderPath")
        undoStack.removeAll()
        canUndo = false

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        let imageURLs = contents.filter { imageExtensions.all.contains($0.pathExtension.lowercased()) }
        images = ImageItem.groupFiles(imageURLs).sorted { $0.baseName < $1.baseName }

        for i in images.indices {
            images[i].rating = MetadataService.readStarRating(from: images[i].primaryURL)
        }

        ImageLoader.shared.clearCache()
        currentIndex = 0
    }

    func restoreLastFolder() {
        guard UserDefaults.standard.object(forKey: "restoreLastFolder") as? Bool ?? true else { return }
        guard let path = UserDefaults.standard.string(forKey: "lastFolderPath") else { return }
        let url = URL(filePath: path)
        guard FileManager.default.fileExists(atPath: path) else { return }
        loadFolder(url)
    }

    func nextImage() {
        guard currentIndex < images.count - 1 else { return }
        currentIndex += 1
    }

    func previousImage() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func deleteCurrent() {
        guard let item = currentImage else { return }

        if UserDefaults.standard.bool(forKey: "confirmDelete") {
            let alert = NSAlert()
            alert.messageText = "Ta bort bild?"
            alert.informativeText = "\(item.displayName)"
            alert.addButton(withTitle: "Ta bort")
            alert.addButton(withTitle: "Avbryt")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }

        do {
            try FileOperations.trashFiles(at: item.urls)
        } catch {
            print("Failed to trash files: \(error)")
            return
        }
        undoStack.append(UndoEntry(item: item, index: currentIndex))
        images.remove(at: currentIndex)
        if currentIndex >= images.count {
            currentIndex = max(0, images.count - 1)
        }
        canUndo = true
    }

    func undoDelete() {
        guard let entry = undoStack.popLast() else { return }

        for url in entry.item.urls {
            let dest = url
            let trashURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".Trash")
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.moveItem(at: trashURL, to: dest)
        }

        images.insert(entry.item, at: entry.index)
        currentIndex = entry.index
        canUndo = !undoStack.isEmpty
    }

    func rateCurrent(_ rating: Int) {
        guard images.indices.contains(currentIndex) else { return }
        images[currentIndex].rating = rating
        MetadataService.setStarRating(rating, for: images[currentIndex].urls)
    }

    func goToImage(at index: Int) {
        guard images.indices.contains(index) else { return }
        currentIndex = index
    }

    func openInEditor() {
        guard let url = currentImage?.primaryURL else { return }
        let editorPath = UserDefaults.standard.string(forKey: "editorAppPath")
        if let editorPath {
            let appURL = URL(fileURLWithPath: editorPath)
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    func handleKeyEvent(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 123: previousImage(); return true
        case 124: nextImage(); return true
        case 51: deleteCurrent(); return true
        case 49: toggleFullscreen(); return true
        default:
            guard let chars = event.charactersIgnoringModifiers else { return false }

            switch chars {
            case "0": rateCurrent(0); return true
            case "1": rateCurrent(1); return true
            case "2": rateCurrent(2); return true
            case "3": rateCurrent(3); return true
            case "4": rateCurrent(4); return true
            case "5": rateCurrent(5); return true
            default: return false
            }
        }
    }

    func handleScrollEvent(_ event: NSEvent) -> Bool {
        guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else { return false }
        if event.scrollingDeltaX > 20 {
            previousImage()
            return true
        } else if event.scrollingDeltaX < -20 {
            nextImage()
            return true
        }
        return false
    }

    private func toggleFullscreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }
}
