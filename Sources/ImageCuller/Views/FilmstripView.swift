import SwiftUI

struct FilmstripView: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var thumbnails: [URL: NSImage] = [:]
    @State private var scrollPosition: Int?

    private let thumbnailWidth: CGFloat = 100
    private let thumbnailHeight: CGFloat = 75

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 6) {
                    ForEach(Array(viewModel.images.enumerated()), id: \.element.id) { idx, item in
                        VStack(spacing: 2) {
                            thumbnailView(for: item)
                                .frame(width: thumbnailWidth, height: thumbnailHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(idx == viewModel.currentIndex ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                                .overlay(alignment: .bottomTrailing) {
                                    if item.isRAW {
                                        Text("RAW")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(.orange)
                                            .padding(3)
                                    }
                                }

                            StarRatingDisplay(rating: item.rating)
                                .font(.system(size: 7))
                        }
                        .frame(width: thumbnailWidth + 8)
                        .onTapGesture {
                            viewModel.goToImage(at: idx)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .onChange(of: viewModel.currentIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(viewModel.images[newIndex].id, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnailView(for item: ImageItem) -> some View {
        if let image = thumbnails[item.primaryURL] {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    ProgressView()
                        .scaleEffect(0.4)
                }
                .task {
                    await loadThumbnail(for: item)
                }
        }
    }

    private func loadThumbnail(for item: ImageItem) async {
        let image = await Task.detached {
            ImageLoader.shared.loadImage(from: item.primaryURL, maxPixelSize: 200)
        }.value
        guard let image else { return }
        await MainActor.run {
            thumbnails[item.primaryURL] = image
        }
    }
}
