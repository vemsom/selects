// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImageCuller",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ImageCuller"
        )
    ]
)
