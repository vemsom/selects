import SwiftUI

struct MetadataPanel: View {
    @Environment(ImageBrowserViewModel.self) private var viewModel
    @State private var metadata: ImageMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let metadata {
                List {
                    Section("Fil") {
                        labelRow("Namn", metadata.filename)
                        labelRow("Storlek", metadata.fileSize)
                        labelRow("Mått", metadata.dimensions)
                        labelRow("Färgrymd", metadata.colorSpace)
                        if let date = metadata.date {
                            labelRow("Datum", date)
                        }
                    }

                    if metadata.camera != nil || metadata.lens != nil {
                        Section("Kamera") {
                            if let camera = metadata.camera {
                                labelRow("Kamera", camera)
                            }
                            if let lens = metadata.lens {
                                labelRow("Objektiv", lens)
                            }
                            if let software = metadata.software {
                                labelRow("Mjukvara", software)
                            }
                        }
                    }

                    Section("Exponering") {
                        if let iso = metadata.iso {
                            labelRow("ISO", iso)
                        }
                        if let aperture = metadata.aperture {
                            labelRow("Bländare", aperture)
                        }
                        if let shutter = metadata.shutterSpeed {
                            labelRow("Slutartid", shutter)
                        }
                        if let fl = metadata.focalLength {
                            labelRow("Brännvidd", fl)
                        }
                        if let flash = metadata.flash {
                            labelRow("Blixt", flash)
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                Spacer()
                ContentUnavailableView(
                    "Ingen metadata",
                    systemImage: "info.circle",
                    description: Text("Välj en bild för att visa\ndess metadata")
                )
                Spacer()
            }
        }
        .frame(minWidth: 200, maxWidth: 280)
        .onChange(of: viewModel.currentImage?.id) { _, _ in
            loadMetadata()
        }
        .onAppear {
            loadMetadata()
        }
    }

    @ViewBuilder
    private func labelRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.callout)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private func loadMetadata() {
        guard let item = viewModel.currentImage else {
            metadata = nil
            return
        }
        let primary = MetadataService.readMetadata(from: item.primaryURL)
        if let raw = item.rawURL {
            let rawMeta = MetadataService.readMetadata(from: raw)
            metadata = rawMeta.merged(with: primary)
        } else {
            metadata = primary
        }
    }
}
