import SwiftUI

struct MainImageView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var nsImage: NSImage?

    var body: some View {
        ZStack {
            Color(.windowBackgroundColor)
                .ignoresSafeArea()

            if let nsImage = nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                ContentUnavailableView(
                    "Ingen bild",
                    systemImage: "photo",
                    description: Text("Välj en mapp i sidofältet\nEller ⌘O för att öppna")
                )
            }

            // Rating overlay top-left
            if let item = viewModel.currentImage, item.rating > 0 {
                VStack {
                    HStack {
                        StarRatingDisplay(rating: item.rating)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding()
                        Spacer()
                    }
                    Spacer()
                }
            }

            // Info overlay bottom
            if let item = viewModel.currentImage {
                VStack {
                    Spacer()
                    HStack {
                        Text(item.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if item.isRAW {
                            Text("RAW")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Text("\(viewModel.currentIndex + 1) / \(viewModel.images.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .padding()
                }
            }
        }
        .onChange(of: viewModel.currentImage?.id) { _, _ in
            loadImage()
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = viewModel.currentImage?.primaryURL else {
            nsImage = nil
            return
        }
        Task.detached {
            let image = ImageLoader.shared.loadImage(from: url, maxPixelSize: 2000)
            await MainActor.run {
                self.nsImage = image
            }
        }
    }
}
