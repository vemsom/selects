import Foundation

enum MetadataService {
    private static let attrName = "com.apple.metadata:kMDItemStarRating"

    static func setStarRating(_ rating: Int, for urls: [URL]) {
        let value = Double(rating)
        guard let plist = try? PropertyListSerialization.data(
            fromPropertyList: value,
            format: .binary,
            options: .zero
        ) else { return }

        for url in urls {
            let path = url.path
            path.withCString { cpath in
                plist.withUnsafeBytes { bytes in
                    _ = setxattr(cpath, attrName, bytes.baseAddress, plist.count, 0, 0)
                }
            }
        }
    }

    static func readStarRating(from url: URL) -> Int {
        let path = url.path
        let size = path.withCString { cpath in
            getxattr(cpath, attrName, nil, 0, 0, 0)
        }
        guard size > 0 else { return 0 }

        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { bytes in
            path.withCString { cpath in
                getxattr(cpath, attrName, bytes.baseAddress, size, 0, 0)
            }
        }
        guard result >= 0 else { return 0 }

        guard let value = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? Double else { return 0 }

        return Int(value)
    }
}
