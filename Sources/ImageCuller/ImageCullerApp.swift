import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewModel: ImageBrowserViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let viewModel = self?.viewModel else { return event }
            return viewModel.handleKeyEvent(event) ? nil : event
        }

        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let viewModel = self?.viewModel else { return event }
            return viewModel.handleScrollEvent(event) ? nil : event
        }
    }
}

@main
struct ImageCullerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = ImageBrowserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .frame(minWidth: 900, minHeight: 500)
                .onAppear {
                    appDelegate.viewModel = viewModel
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Öppna mapp...") {
                    viewModel.openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
