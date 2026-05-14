import SwiftUI

struct ContentView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @AppStorage("showMetadata") private var showMetadata = false

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    MainImageView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if showMetadata {
                        Divider()
                        MetadataPanel()
                            .frame(width: 240)
                    }
                }

                Divider()
                FilmstripView()
                    .padding(.bottom, 6)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
