import Foundation
import PDFKit
import Testing
import UIKit
@testable import Closeout

struct PDFReportTests {
    private func dec(_ value: String) -> Decimal { Decimal(string: value) ?? 0 }

    private func makeStore() throws -> EvidenceStore {
        let store = EvidenceStore(directory: FileManager.default.temporaryDirectory.appending(path: "report-\(UUID().uuidString)"))
        return store
    }

    private func sampleData(photos: [ReportData.Photo] = [], receipts: Int = 2) -> ReportData {
        let totals = JobTotals(
            pricing: .hourly, hourlyRate: dec("140"), laborHours: 8, fixedPrice: 0, materials: dec("180"),
            receipts: [(dec("86.40"), true), (dec("93.60"), true)], mileage: [(18.4, dec("1.20"))]
        )
        var data = ReportData(
            branding: .init(businessName: "Hoà Bình Điện Lực", contactLine: "(503) 555-0142 · hello@hoabinh.example", logoFileName: nil),
            jobNumber: "#CL-0142", dateRange: "Nov 12 – Nov 14", title: "Replace kitchen supply line",
            notes: "Replaced the supply line and tested pressure at 60 psi.",
            clientName: "Marta Ruiz", clientContact: "marta@example.com", siteAddress: "418 Alder St, Portland OR",
            photos: photos,
            receipts: (0..<receipts).map { ReportData.ReceiptRow(date: .now, merchant: "Merchant \($0)", amount: dec("86.40")) },
            mileage: [ReportData.MileageRow(route: "Depot → Alder St", miles: 18.4, cost: dec("22.08"))],
            totals: totals, laborHours: 8, currencyCode: "USD", footerNote: "Cảm ơn quý khách", includeSignature: true
        )
        data.locale = Locale(identifier: "en_US")
        return data
    }

    /// NFC, with Đ folded to Eth: the font draws one shared glyph for both, so PDF text extraction returns U+00D0.
    private func normalized(_ string: String?) -> String {
        (string ?? "").precomposedStringWithCanonicalMapping.replacingOccurrences(of: "Đ", with: "Ð")
    }

    @Test func rendersOnePageLetterWithTextAndVietnamese() throws {
        let pdf = PDFReportRenderer.render(sampleData())
        let document = try #require(PDFDocument(data: pdf))
        #expect(document.pageCount == 1)
        let page = try #require(document.page(at: 0))
        let size = page.bounds(for: .mediaBox).size
        #expect(size == ReportPageSize.letter.size)

        let text = normalized(document.string)
        #expect(text.contains("Marta Ruiz"))
        #expect(text.contains("$1,502.08"))
        // Vietnamese diacritics must survive (system font cascade, no tofu / dropped glyphs).
        #expect(text.contains(normalized("Hoà Bình Điện Lực")))
        #expect(text.contains(normalized("Cảm ơn quý khách")))

        let snapshot = page.thumbnail(of: CGSize(width: 612, height: 792), for: .mediaBox)
        if let png = snapshot.pngData() {
            Attachment.record(png, named: "report-page-1.png")
        }
    }

    @Test func a4PageSize() throws {
        var data = sampleData()
        data.pageSize = .a4
        let document = try #require(PDFDocument(data: PDFReportRenderer.render(data)))
        #expect(document.pageCount == 1)
        #expect(document.page(at: 0)?.bounds(for: .mediaBox).size == ReportPageSize.a4.size)
    }

    @Test func manyRowsAndPhotosStillOnePage() throws {
        let store = try makeStore()
        defer { store.removeAll() }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400)).jpegData(withCompressionQuality: 0.9) { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
        }
        let photos = try (0..<8).map { ReportData.Photo(fileName: try store.save(image), label: "site \($0)") }
        let pdf = PDFReportRenderer.render(sampleData(photos: photos, receipts: 40), store: store)
        let document = try #require(PDFDocument(data: pdf))
        #expect(document.pageCount == 1)
        #expect(normalized(document.string).contains("more"))
    }

    @Test func freeReportIsUnbrandedWithMadeWithFooter() throws {
        var data = sampleData()
        data.branding = nil
        let document = try #require(PDFDocument(data: PDFReportRenderer.render(data)))
        let text = normalized(document.string)
        #expect(text.contains("Made with Closeout"))
        #expect(!text.contains(normalized("Hoà Bình Điện Lực")))
    }

    @Test func pageSizeFollowsRegion() {
        #expect(ReportPageSize.forRegion(.unitedStates) == .letter)
        #expect(ReportPageSize.forRegion(.canada) == .letter)
        #expect(ReportPageSize.forRegion(.vietnam) == .a4)
    }
}
