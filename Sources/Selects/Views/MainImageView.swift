import SwiftUI

struct MainImageView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @AppStorage("backgroundStyle") private var backgroundStyle = 0
    @State private var nsImage: NSImage?

    private var bgColor: Color {
        switch backgroundStyle {
        case 1: return .black
        case 2: return Color(.darkGray)
        case 3: return .white
        default: return Color(.windowBackgroundColor)
        }
    }

    var body: some View {
        ZStack {
            bgColor

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
        }
        .background(
            ScrollWheelCapture { delta in
                if delta < 0 {
                    viewModel.previousImage()
                } else {
                    viewModel.nextImage()
                }
            }
        )
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
