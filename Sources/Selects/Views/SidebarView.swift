import SwiftUI

struct SidebarView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var folderTree: [FolderItem] = []
    @State private var volumeItems: [FolderItem] = []

    private let home = FileManager.default.homeDirectoryForCurrentUser
    private let volumes = URL(filePath: "/Volumes")

    var body: some View {
        List {
            Section("Datorn") {
                ForEach(folderTree) { folder in
                    FolderRow(folder: folder)
                }
            }

            Section("Volymer") {
                ForEach(volumeItems) { vol in
                    FolderRow(folder: vol)
                }
            }
        }
        .listStyle(.sidebar)
        .onAppear {
            loadTree()
        }
    }

    private func loadTree() {
        let candidates = ["Bilder", "Pictures", "Desktop", "Downloads"]
            .map { home.appendingPathComponent($0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }

        folderTree = candidates.map { FolderItem(url: $0) }

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: volumes,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            volumeItems = contents.map { FolderItem(url: $0) }
        }
    }
}

struct FolderRow: View {
    let folder: FolderItem
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var isExpanded = false
    @State private var children: [FolderItem]?

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let children = children {
                ForEach(children) { child in
                    FolderRow(folder: child)
                }
            } else if isExpanded {
                ProgressView()
                    .scaleEffect(0.5)
                    .task { loadChildren() }
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.accentColor)
                Text(folder.name)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.loadFolder(folder.url)
            }
        }
    }

    private func loadChildren() {
        children = FolderItem.loadChildren(from: folder.url)
    }
}
