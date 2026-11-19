import Foundation
import Testing
import UIKit
@testable import Closeout

struct ReceiptParserTests {
    private let now = Date(timeIntervalSince1970: 1_795_000_000) // ~Nov 18 2026

    @Test func parsesTypicalUSReceipt() {
        let parsed = ReceiptParser.parse(lines: [
            "HOME DEPOT #1142", "1450 Main St", "Portland OR", "11/13/2026 10:42 AM",
            "PEX Pipe 3/4  $52.40", "Fittings  $29.00", "SUBTOTAL  $81.40", "TAX  $5.00", "TOTAL  $86.40", "VISA ****1234"
        ], now: now)
        #expect(parsed.merchant == "HOME DEPOT #1142")
        #expect(parsed.total == Decimal(string: "86.40"))
        let date = parsed.date.map { Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: $0) }
        #expect(date?.month == 11 && date?.day == 13 && date?.year == 2026)
    }

    @Test func totalOnNextLine() {
        let parsed = ReceiptParser.parse(lines: ["Ferguson Supply", "Subtotal", "88.00", "Total", "93.60"], now: now)
        #expect(parsed.total == Decimal(string: "93.60"))
    }

    @Test func thousandsAndEuropeanSeparators() {
        #expect(ReceiptParser.parse(lines: ["Shop", "TOTAL 1,234.56"], now: now).total == Decimal(string: "1234.56"))
        #expect(ReceiptParser.parse(lines: ["Shop", "TOTAL 1.234,56"], now: now).total == Decimal(string: "1234.56"))
        #expect(ReceiptParser.parse(lines: ["Shop", "Tổng cộng 86,40"], now: now).total == Decimal(string: "86.40"))
    }

    @Test func fallsBackToLargestAmountWithoutKeyword() {
        let parsed = ReceiptParser.parse(lines: ["Cafe Luna", "Latte 4.50", "Bagel 3.25", "7.75"], now: now)
        #expect(parsed.total == Decimal(string: "7.75"))
    }

    @Test func missingFieldsStayNil() {
        let parsed = ReceiptParser.parse(lines: ["###", "12"], now: now)
        #expect(parsed.merchant == nil && parsed.total == nil && parsed.date == nil)
    }
}

struct ReceiptOCRTests {
    /// Renders a receipt-like image and runs real Vision OCR on it (works in the simulator, no camera needed).
    @Test func ocrFixtureImagePrefillsMerchantAndTotal() async throws {
        let lines = ["HOME DEPOT #1142", "Pipe fittings   52.40", "SUBTOTAL   81.40", "TOTAL   86.40", "11/13/2026"]
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 800)).jpegData(withCompressionQuality: 1) { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1000, height: 800))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 56, weight: .bold), .foregroundColor: UIColor.black
            ]
            for (index, line) in lines.enumerated() {
                line.draw(at: CGPoint(x: 40, y: 40 + CGFloat(index) * 130), withAttributes: attributes)
            }
        }
        let recognized = try await ReceiptScanner.recognize(image)
        let parsed = ReceiptParser.parse(lines: recognized.lines)
        #expect(parsed.merchant?.uppercased().contains("HOME DEPOT") == true)
        #expect(parsed.total == Decimal(string: "86.40"))
        #expect(recognized.confidence > 0.5)
    }
}

struct MileageTests {
    @Test func entryCostRoundsToCents() {
        let entry = MileageEntry(miles: 18.4, ratePerMile: Decimal(string: "1.20") ?? 0)
        #expect(entry.cost == Decimal(string: "22.08"))
        #expect(MileageEntry(miles: 1, startLabel: "Depot", endLabel: "Alder St", ratePerMile: 1).routeText == "Depot → Alder St")
    }
}
