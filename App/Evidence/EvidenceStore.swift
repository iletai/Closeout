import Foundation
import ImageIO
import UniformTypeIdentifiers

enum EvidenceError: Error {
    case unreadableImage
    case writeFailed
}

/// Stores job images as JPEG files under Application Support/Evidence (never in the database).
struct EvidenceStore: Sendable {
    static let maxLongEdge = 2048
    static let jpegQuality = 0.8

    let directory: URL

    static let shared = EvidenceStore(
        directory: URL.applicationSupportDirectory.appending(path: "Evidence", directoryHint: .isDirectory)
    )

    func url(for fileName: String) -> URL { directory.appending(path: fileName) }

    /// Downscales to `maxLongEdge` (never upscales), bakes in orientation, writes JPEG q0.8. Returns the file name.
    func save(_ data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { throw EvidenceError.unreadableImage }
        let longEdge = Self.longEdge(of: source)
        guard let image = Self.downscaled(source, maxPixel: min(longEdge, Self.maxLongEdge)) else {
            throw EvidenceError.unreadableImage
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = UUID().uuidString + ".jpg"
        guard let destination = CGImageDestinationCreateWithURL(
            url(for: fileName) as CFURL, UTType.jpeg.identifier as CFString, 1, nil
        ) else { throw EvidenceError.writeFailed }
        CGImageDestinationAddImage(
            destination, image, [kCGImageDestinationLossyCompressionQuality: Self.jpegQuality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { throw EvidenceError.writeFailed }
        return fileName
    }

    func delete(_ fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }

    func exists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: fileName).path)
    }

    /// Small decoded image for grids and previews.
    func thumbnail(_ fileName: String, maxPixel: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url(for: fileName) as CFURL, nil) else { return nil }
        return Self.downscaled(source, maxPixel: maxPixel)
    }

    static func thumbnail(from data: Data, maxPixel: Int) -> CGImage? {
        CGImageSourceCreateWithData(data as CFData, nil).flatMap { downscaled($0, maxPixel: maxPixel) }
    }

    private static func longEdge(of source: CGImageSource) -> Int {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? maxLongEdge
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? maxLongEdge
        return max(width, height)
    }

    private static func downscaled(_ source: CGImageSource, maxPixel: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
