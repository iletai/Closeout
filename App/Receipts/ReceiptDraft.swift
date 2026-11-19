import Foundation

/// Editable receipt fields (OCR prefill or an existing receipt).
struct ReceiptDraft {
    var merchantName = ""
    var total = Decimal.zero
    var purchasedAt = Date.now
    var isReimbursable = true
    /// 0...1, zero when typed by hand.
    var ocrConfidence = 0.0
    var imageData: Data?

    init() {}

    init(receipt: Receipt) {
        merchantName = receipt.merchantName
        total = receipt.total
        purchasedAt = receipt.purchasedAt
        isReimbursable = receipt.isReimbursable
        ocrConfidence = receipt.ocrConfidence
    }

    init(recognized: RecognizedText, imageData: Data) {
        let parsed = ReceiptParser.parse(lines: recognized.lines)
        merchantName = parsed.merchant ?? ""
        total = parsed.total ?? 0
        purchasedAt = parsed.date ?? .now
        ocrConfidence = recognized.confidence
        self.imageData = imageData
    }

    func apply(to receipt: Receipt) {
        receipt.merchantName = merchantName.trimmingCharacters(in: .whitespaces)
        receipt.total = total
        receipt.purchasedAt = purchasedAt
        receipt.isReimbursable = isReimbursable
    }
}
