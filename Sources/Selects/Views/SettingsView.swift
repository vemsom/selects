import SwiftUI

struct SettingsView: View {
    @AppStorage("filmstripSize") private var filmstripSize = 100.0
    @AppStorage("editorAppPath") private var editorAppPath = ""
    @AppStorage("confirmDelete") private var confirmDelete = true
    @AppStorage("restoreLastFolder") private var restoreLastFolder = true

    private var editorURL: URL? {
        editorAppPath.isEmpty ? nil : URL(fileURLWithPath: editorAppPath)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Filmremsa").font(.headline)
                HStack {
                    Text("Storlek")
                    Slider(value: $filmstripSize, in: 60...320, step: 10)
                    Text("\(Int(filmstripSize)) px").frame(width: 50)
                }
            }

            Divider()

            Group {
                Text("Extern redigerare").font(.headline)
                HStack {
                    if let url = editorURL {
                        let icon = NSWorkspace.shared.icon(forFile: url.path)
                        Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                        Text(url.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                    } else {
                        Image(systemName: "square.and.pencil")
                        Text("Systemstandard")
                    }
                    Spacer()
                    Button("Välj...") { chooseEditor() }
                    if !editorAppPath.isEmpty {
                        Button("Återställ") { editorAppPath = "" }
                    }
                }
            }

            Divider()

            Group {
                Text("Beteende").font(.headline)
                Toggle("Bekräfta före radering", isOn: $confirmDelete)
                Toggle("Återställ senaste mappen vid start", isOn: $restoreLastFolder)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private func chooseEditor() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.message = "Välj ett bildredigeringsprogram"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        editorAppPath = url.path
    }
}
