import Foundation
import Vision

struct RecognizedText: Sendable {
    let lines: [String]
    /// Average Vision confidence, 0...1.
    let confidence: Double
}

/// On-device OCR (Vision). Nothing leaves the phone.
enum ReceiptScanner {
    static func recognize(_ imageData: Data) async throws -> RecognizedText {
        guard let image = EvidenceStore.thumbnail(from: imageData, maxPixel: EvidenceStore.maxLongEdge) else {
            throw EvidenceError.unreadableImage
        }
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        let observations = try await request.perform(on: image)
        // Vision's origin is bottom-left: sort by descending Y to read top to bottom.
        let ordered = observations
            .sorted { $0.boundingBox.cgRect.midY > $1.boundingBox.cgRect.midY }
            .compactMap { $0.topCandidates(1).first }
        let confidence = ordered.isEmpty ? 0 : ordered.map { Double($0.confidence) }.reduce(0, +) / Double(ordered.count)
        return RecognizedText(lines: ordered.map(\.string), confidence: confidence)
    }
}
