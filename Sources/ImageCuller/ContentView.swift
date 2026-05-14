import SwiftUI

struct ContentView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                MainImageView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !viewModel.images.isEmpty {
                    Divider()
                    FilmstripView()
                        .frame(height: 120)
                        .padding(.bottom, 6)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
