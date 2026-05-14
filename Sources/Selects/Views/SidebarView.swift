import SwiftUI

struct SidebarView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var folderTree: [FolderItem] = []
    @State private var volumeItems: [FolderItem] = []
    @State private var favoritePaths: [String] = []

    private let home = FileManager.default.homeDirectoryForCurrentUser
    private let volumes = URL(filePath: "/Volumes")
    private let favKey = "sidebar_favorites"

    private let favChanged = Notification.Name("favoritesChanged")

    var body: some View {
        List {
            Section("Favoriter") {
                if favoritePaths.isEmpty {
                    Text("Hovra över en mapp och klicka på stjärnan")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                ForEach(favoritePaths, id: \.self) { path in
                    FolderRow(folder: FolderItem(url: URL(filePath: path)))
                }
            }

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
            reloadFavorites()
        }
        .onReceive(NotificationCenter.default.publisher(for: favChanged)) { _ in
            reloadFavorites()
        }
    }

    private func reloadFavorites() {
        favoritePaths = UserDefaults.standard.stringArray(forKey: favKey) ?? []
    }

    static func notifyFavoritesChanged() {
        NotificationCenter.default.post(name: Notification.Name("favoritesChanged"), object: nil)
    }

    private func addFavorite(_ url: URL) {
        var paths = UserDefaults.standard.stringArray(forKey: favKey) ?? []
        let path = url.path
        guard !paths.contains(path) else { return }
        paths.append(path)
        UserDefaults.standard.set(paths, forKey: favKey)
        Self.notifyFavoritesChanged()
    }

    private func removeFavorite(_ path: String) {
        var paths = UserDefaults.standard.stringArray(forKey: favKey) ?? []
        paths.removeAll { $0 == path }
        UserDefaults.standard.set(paths, forKey: favKey)
        Self.notifyFavoritesChanged()
    }

    private func loadTree() {
        let common = ["Desktop", "Documents", "Downloads", "Pictures", "Movies", "Music"]
        folderTree = common
            .map { home.appendingPathComponent($0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .map { FolderItem(url: $0) }

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: volumes,
            includingPropertiesForKeys: [.volumeUUIDStringKey],
            options: .skipsHiddenFiles
        ) {
            let rootUUID = try? URL(fileURLWithPath: "/")
                .resourceValues(forKeys: [.volumeUUIDStringKey]).volumeUUIDString

            volumeItems = contents.compactMap { url in
                let uuid = try? url.resourceValues(forKeys: [.volumeUUIDStringKey]).volumeUUIDString
                guard uuid != rootUUID else { return nil }
                return FolderItem(url: url)
            }
        }
    }
}

struct FolderRow: View {
    let folder: FolderItem
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var isExpanded = false
    @State private var children: [FolderItem]?
    @State private var isHovering = false

    private var isActive: Bool {
        viewModel.currentFolder?.path == folder.url.path
    }

    private var isFavorited: Bool {
        let paths = UserDefaults.standard.stringArray(forKey: "sidebar_favorites") ?? []
        return paths.contains(folder.url.path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 12)
                    .onTapGesture {
                        if children == nil { loadChildren() }
                        withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                    }

                Image(systemName: isActive ? "folder.fill" : "folder")
                    .foregroundColor(.accentColor)

                Text(folder.name)
                    .lineLimit(1)
                    .fontWeight(isActive ? .semibold : .regular)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([folder.url])
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("Visa i Finder")
                    .opacity(isHovering ? 1 : 0)
                    .allowsHitTesting(isHovering)

                    Button {
                        var paths = UserDefaults.standard.stringArray(forKey: "sidebar_favorites") ?? []
                        let path = folder.url.path
                        if paths.contains(path) {
                            paths.removeAll { $0 == path }
                        } else {
                            paths.append(path)
                        }
                        UserDefaults.standard.set(paths, forKey: "sidebar_favorites")
                        SidebarView.notifyFavoritesChanged()
                    } label: {
                        Image(systemName: isFavorited ? "star.fill" : "star")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isFavorited ? .accentColor : .secondary)
                }
                .opacity((isFavorited || isHovering) ? 1 : 0)
                .allowsHitTesting(isFavorited || isHovering)
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.loadFolder(folder.url)
                if children == nil { loadChildren() }
                withAnimation(.easeInOut(duration: 0.15)) { isExpanded = true }
            }
            .onHover { isHovering = $0 }
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.accentColor.opacity(0.12) : Color.clear)
            )

            if isExpanded {
                if let children = children {
                    ForEach(children) { child in
                        FolderRow(folder: child)
                            .padding(.leading, 14)
                    }
                } else {
                    HStack {
                        Rectangle().fill(.clear).frame(width: 28)
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    .padding(.leading, 14)
                    .task { loadChildren() }
                }
            }
        }
    }

    private func loadChildren() {
        children = FolderItem.loadChildren(from: folder.url)
    }
}


