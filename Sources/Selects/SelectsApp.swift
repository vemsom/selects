import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: ImageBrowserViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let viewModel = self?.viewModel else { return event }
            return viewModel.handleKeyEvent(event) ? nil : event
        }
    }
}

@main
struct SelectsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = ImageBrowserViewModel()
    @AppStorage("showMetadata") private var showMetadata = false
    @AppStorage("backgroundStyle") private var backgroundStyle = 0
    @AppStorage("editorAppPath") private var editorAppPath = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .frame(minWidth: 900, minHeight: 500)
                .onAppear {
                    appDelegate.viewModel = viewModel
                    viewModel.restoreLastFolder()
                }
        }
        .commands {
            CommandMenu("Redigera") {
                Button("Ångra radering") {
                    viewModel.undoDelete()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!viewModel.canUndo)
            }

            CommandGroup(replacing: .newItem) {
                Button("Öppna mapp...") {
                    viewModel.openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu("Bild") {
                Button("Öppna i redigerare") {
                    viewModel.openInEditor()
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            CommandMenu("Visa") {
                Toggle("Metadata", isOn: $showMetadata)
                    .keyboardShortcut("i", modifiers: .command)

                Divider()

                Picker("Bakgrundsfärg", selection: $backgroundStyle) {
                    Text("System").tag(0)
                    Text("Svart").tag(1)
                    Text("Grå").tag(2)
                    Text("Vit").tag(3)
                }
                .pickerStyle(.menu)
            }
        }

        Settings {
            SettingsView()
        }
    }
}
