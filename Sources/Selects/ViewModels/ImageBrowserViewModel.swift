import SwiftUI

@Observable
final class ImageBrowserViewModel {
    private(set) var images: [ImageItem] = []
    private(set) var currentIndex: Int = 0
    private(set) var currentFolder: URL?

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
        do {
            try FileOperations.trashFiles(at: item.urls)
        } catch {
            print("Failed to trash files: \(error)")
        }
        images.remove(at: currentIndex)
        if currentIndex >= images.count {
            currentIndex = max(0, images.count - 1)
        }
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
