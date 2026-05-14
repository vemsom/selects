import Foundation
import ImageIO

struct ImageMetadata {
    let filename: String
    let fileSize: String
    let dimensions: String
    let colorSpace: String
    let date: String?
    let camera: String?
    let iso: String?
    let aperture: String?
    let shutterSpeed: String?
    let focalLength: String?
    let lens: String?
    let flash: String?
    let software: String?

    func merged(with other: ImageMetadata) -> ImageMetadata {
        ImageMetadata(
            filename: filename,
            fileSize: fileSize,
            dimensions: dimensions,
            colorSpace: colorSpace,
            date: date ?? other.date,
            camera: camera ?? other.camera,
            iso: iso ?? other.iso,
            aperture: aperture ?? other.aperture,
            shutterSpeed: shutterSpeed ?? other.shutterSpeed,
            focalLength: focalLength ?? other.focalLength,
            lens: lens ?? other.lens,
            flash: flash ?? other.flash,
            software: software ?? other.software
        )
    }
}

enum MetadataService {
    private static let attrName = "com.apple.metadata:kMDItemStarRating"

    static func readMetadata(from url: URL) -> ImageMetadata {
        let filename = url.lastPathComponent

        let fileSize: String = {
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attrs?[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: size)
            }
            return "–"
        }()

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else {
            return ImageMetadata(
                filename: filename, fileSize: fileSize, dimensions: "–", colorSpace: "–",
                date: nil, camera: nil, iso: nil, aperture: nil,
                shutterSpeed: nil, focalLength: nil, lens: nil,
                flash: nil, software: nil
            )
        }

        let w = props[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let h = props[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        let dimensions = "\(w) × \(h)"

        let colorSpace = props[kCGImagePropertyColorModel as String] as? String ?? "–"

        let tiff = props[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any]

        let date = tiff?[kCGImagePropertyTIFFDateTime as String] as? String
        let camera: String? = {
            let make = tiff?[kCGImagePropertyTIFFMake as String] as? String
            let model = tiff?[kCGImagePropertyTIFFModel as String] as? String
            if let make, let model { return "\(make) \(model)" }
            return model ?? make
        }()
        let software = tiff?[kCGImagePropertyTIFFSoftware as String] as? String

        let iso: String? = {
            guard let v = exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let first = v.first
            else { return nil }
            return "\(first)"
        }()

        let aperture: String? = {
            guard let v = exif?[kCGImagePropertyExifApertureValue as String] as? Double else { return nil }
            return String(format: "ƒ/%.1f", v)
        }()

        let shutterSpeed: String? = {
            guard let v = exif?[kCGImagePropertyExifShutterSpeedValue as String] as? Double else { return nil }
            let seconds = exp2(-v)
            if seconds >= 1 { return "\(Int(seconds))″" }
            let numerator = Int(round(1.0 / seconds))
            return "¹⁄\(numerator)″"
        }()

        let focalLength: String? = {
            guard let v = exif?[kCGImagePropertyExifFocalLength as String] as? Double else { return nil }
            return "\(Int(v)) mm"
        }()

        let lens = exif?[kCGImagePropertyExifLensModel as String] as? String
        let flash = exif?[kCGImagePropertyExifFlash as String] as? Int

        return ImageMetadata(
            filename: filename, fileSize: fileSize, dimensions: dimensions,
            colorSpace: colorSpace, date: date, camera: camera,
            iso: iso, aperture: aperture, shutterSpeed: shutterSpeed,
            focalLength: focalLength, lens: lens,
            flash: flash != nil ? (flash == 1 ? "Ja" : "Nej") : nil,
            software: software
        )
    }

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
