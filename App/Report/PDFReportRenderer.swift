import PDFKit
import UIKit

/// Renders the one-page job report with UIGraphicsPDFRenderer. Text goes through NSAttributedString (CoreText) with
/// the system font, whose cascade covers Vietnamese diacritics. Sections that do not fit are cut with "+N more".
enum PDFReportRenderer {
    static func render(_ data: ReportData, store: EvidenceStore = .shared) -> Data {
        let bounds = CGRect(origin: .zero, size: data.pageSize.size)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(data.jobNumber) \(data.clientName)",
            kCGPDFContextCreator as String: "Closeout"
        ]
        return UIGraphicsPDFRenderer(bounds: bounds, format: format).pdfData { context in
            context.beginPage()
            ReportPage(data: data, store: store, bounds: bounds, cg: context.cgContext).draw()
        }
    }
}

private enum Palette {
    static let ink = UIColor(red: 0x12 / 255, green: 0x18 / 255, blue: 0x1F / 255, alpha: 1)
    static let rust = UIColor(red: 0xC2 / 255, green: 0x41 / 255, blue: 0x0C / 255, alpha: 1)
    static let muted = UIColor(red: 0x6B / 255, green: 0x6F / 255, blue: 0x76 / 255, alpha: 1)
    static let line = UIColor(red: 0xE3 / 255, green: 0xDE / 255, blue: 0xD4 / 255, alpha: 1)
    static let placeholder = UIColor(red: 0xD5 / 255, green: 0xDB / 255, blue: 0xE0 / 255, alpha: 1)
}

private final class ReportPage {
    let data: ReportData
    let store: EvidenceStore
    let bounds: CGRect
    let cg: CGContext
    let margin: CGFloat = 40
    let rowHeight: CGFloat = 15
    var y: CGFloat = 40

    var left: CGFloat { margin }
    var right: CGFloat { bounds.width - margin }
    var width: CGFloat { bounds.width - 2 * margin }
    /// Space the totals block and footer always need at the bottom.
    var reservedBottom: CGFloat { 190 }

    init(data: ReportData, store: EvidenceStore, bounds: CGRect, cg: CGContext) {
        self.data = data
        self.store = store
        self.bounds = bounds
        self.cg = cg
    }

    func draw() {
        header()
        clientBlock()
        workBlock()
        photoSheet()
        receiptsTable()
        mileageTable()
        totalsBlock()
        footer()
    }

    // MARK: Sections

    private func header() {
        if let branding = data.branding {
            let logo = CGRect(x: left, y: y, width: 40, height: 40)
            drawLogo(branding, in: logo)
            text(branding.businessName, .systemFont(ofSize: 15, weight: .semibold), Palette.ink, x: left + 52, width: width - 52)
            if !branding.contactLine.isEmpty {
                text(branding.contactLine, .systemFont(ofSize: 9), Palette.muted, x: left + 52, y: y + 20, width: width - 52)
            }
            y += 52
        }
        rule(at: y, color: Palette.rust, lineWidth: 2)
        y += 8
        text(String(localized: "JOB REPORT"), .systemFont(ofSize: 9, weight: .semibold), Palette.muted, width: width / 2, kern: 1.1)
        let meta = [data.jobNumber, data.dateRange].filter { !$0.isEmpty }.joined(separator: " · ")
        text(meta, .monospacedSystemFont(ofSize: 8, weight: .regular), Palette.muted, x: left + width / 2, width: width / 2, align: .right)
        y += 24
    }

    private func clientBlock() {
        let leftWidth = width * 0.6
        var blockHeight = text(String(localized: "Prepared for"), .systemFont(ofSize: 8), Palette.muted, width: leftWidth)
        blockHeight += text(data.clientName, .systemFont(ofSize: 14, weight: .semibold), Palette.ink, y: y + blockHeight, width: leftWidth)
        for line in [data.siteAddress, data.clientContact] where !line.isEmpty {
            blockHeight += text(line, .systemFont(ofSize: 9), Palette.muted, y: y + blockHeight, width: leftWidth)
        }
        text(String(localized: "Total"), .systemFont(ofSize: 8), Palette.muted, x: left + leftWidth, width: width - leftWidth, align: .right)
        text(money(data.totals.total), .monospacedSystemFont(ofSize: 14, weight: .bold), Palette.ink,
             x: left + leftWidth, y: y + 12, width: width - leftWidth, align: .right)
        y += max(blockHeight, 34) + 14
    }

    private func workBlock() {
        let body = [data.title, data.notes].filter { !$0.isEmpty }.joined(separator: "\n")
        guard !body.isEmpty else { return }
        label(String(localized: "WORK COMPLETED"))
        y += text(body, .systemFont(ofSize: 9), Palette.ink.withAlphaComponent(0.85), width: width, maxHeight: 64) + 14
    }

    private func photoSheet() {
        let photos = Array(data.photos.prefix(6))
        guard !photos.isEmpty else { return }
        let gap: CGFloat = 4
        let cell = (width - 2 * gap) / 3
        let height = cell * 0.55
        for (index, photo) in photos.enumerated() {
            let column = CGFloat(index % 3)
            let row = CGFloat(index / 3)
            let rect = CGRect(x: left + column * (cell + gap), y: y + row * (height + 16), width: cell, height: height)
            drawPhoto(photo, in: rect)
            text(photo.label, .monospacedSystemFont(ofSize: 7, weight: .regular), Palette.muted,
                 x: rect.minX, y: rect.maxY + 2, width: cell)
        }
        y += CGFloat((photos.count + 2) / 3) * (height + 16) + 6
    }

    private func receiptsTable() {
        guard !data.receipts.isEmpty else { return }
        let rows = fittingRows(for: data.receipts.count)
        guard rows > 0 else { return }
        label(String(localized: "RECEIPTS"))
        let shown = rows < data.receipts.count ? rows - 1 : rows
        for receipt in data.receipts.prefix(shown) {
            text(receipt.date.formatted(.dateTime.month(.abbreviated).day().locale(data.locale)),
                 .monospacedSystemFont(ofSize: 8.5, weight: .regular), Palette.muted, width: 60)
            text(receipt.merchant, .systemFont(ofSize: 8.5), Palette.ink, x: left + 70, width: width - 160)
            text(money(receipt.amount), .monospacedSystemFont(ofSize: 8.5, weight: .regular), Palette.ink,
                 x: right - 90, width: 90, align: .right)
            y += rowHeight
        }
        moreRow(hidden: data.receipts.count - shown)
        y += 10
    }

    private func mileageTable() {
        guard !data.mileage.isEmpty else { return }
        let rows = fittingRows(for: data.mileage.count)
        guard rows > 0 else { return }
        label(String(localized: "MILEAGE"))
        let shown = rows < data.mileage.count ? rows - 1 : rows
        for entry in data.mileage.prefix(shown) {
            text(entry.route.isEmpty ? String(localized: "Mileage") : entry.route, .systemFont(ofSize: 8.5), Palette.ink,
                 width: width - 190)
            text("\(entry.miles.formatted(.number.locale(data.locale))) mi", .monospacedSystemFont(ofSize: 8.5, weight: .regular),
                 Palette.muted, x: right - 180, width: 80, align: .right)
            text(money(entry.cost), .monospacedSystemFont(ofSize: 8.5, weight: .regular), Palette.ink,
                 x: right - 90, width: 90, align: .right)
            y += rowHeight
        }
        moreRow(hidden: data.mileage.count - shown)
        y += 10
    }

    private func totalsBlock() {
        let totals = data.totals
        let hours = data.laborHours.map { " \($0.formatted(.number.locale(data.locale))) h" } ?? ""
        let lines: [(String, Decimal)] = [
            (String(localized: "Labor") + hours, totals.labor),
            (String(localized: "Materials"), totals.materials),
            (String(localized: "Mileage"), totals.mileageCost),
            (String(localized: "Receipts"), totals.expenses)
        ]
        let blockLeft = right - width * 0.55
        y = max(y, bounds.height - reservedBottom + 20)
        for (title, amount) in lines {
            leaderRow(title, money(amount), blockLeft: blockLeft)
            y += rowHeight
        }
        y += 2
        rule(at: y, from: blockLeft, color: Palette.rust, lineWidth: 1)
        y += 6
        text(String(localized: "TOTAL"), .systemFont(ofSize: 9, weight: .semibold), Palette.ink, x: blockLeft, width: 80)
        text(money(totals.total), .monospacedSystemFont(ofSize: 15, weight: .bold), Palette.ink,
             x: blockLeft, y: y - 3, width: right - blockLeft, align: .right)
    }

    private func footer() {
        var footerY = bounds.height - margin - 12
        let footerText = data.branding == nil
            ? String(localized: "Work summary, not a tax invoice. Made with Closeout.")
            : String(localized: "Work summary, not a tax invoice.")
        text(footerText, .systemFont(ofSize: 7), Palette.muted, y: footerY, width: width)
        if !data.footerNote.isEmpty {
            footerY -= 12
            text(data.footerNote, .systemFont(ofSize: 8), Palette.ink, y: footerY, width: width)
        }
        if data.includeSignature {
            let lineY = footerY - 34
            rule(at: lineY, to: left + 140, color: Palette.muted, lineWidth: 0.5)
            text(String(localized: "Client signature"), .systemFont(ofSize: 7), Palette.muted,
                 x: left, y: lineY + 3, width: 140)
        }
    }

    // MARK: Helpers

    private func fittingRows(for count: Int) -> Int {
        let available = bounds.height - reservedBottom - y - 24
        return min(count, max(0, Int(available / rowHeight)))
    }

    private func moreRow(hidden: Int) {
        guard hidden > 0 else { return }
        text(String(localized: "+\(hidden) more"), .systemFont(ofSize: 8), Palette.muted, width: width)
        y += rowHeight
    }

    private func label(_ string: String) {
        text(string, .systemFont(ofSize: 8, weight: .semibold), Palette.muted, width: width, kern: 0.9)
        y += 13
    }

    private func money(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: data.currencyCode).locale(data.locale))
    }

    private func leaderRow(_ title: String, _ value: String, blockLeft: CGFloat) {
        let titleFont = UIFont.systemFont(ofSize: 8.5)
        let valueFont = UIFont.monospacedSystemFont(ofSize: 8.5, weight: .regular)
        let titleWidth = (title as NSString).size(withAttributes: [.font: titleFont]).width
        let valueWidth = (value as NSString).size(withAttributes: [.font: valueFont]).width
        text(title, titleFont, Palette.ink, x: blockLeft, width: right - blockLeft)
        text(value, valueFont, Palette.ink, x: blockLeft, width: right - blockLeft, align: .right)
        cg.saveGState()
        cg.setStrokeColor(Palette.muted.cgColor)
        cg.setLineWidth(0.5)
        cg.setLineDash(phase: 0, lengths: [1, 2.5])
        let dotsY = y + 9
        cg.move(to: CGPoint(x: blockLeft + titleWidth + 4, y: dotsY))
        cg.addLine(to: CGPoint(x: right - valueWidth - 4, y: dotsY))
        cg.strokePath()
        cg.restoreGState()
    }

    private func rule(at lineY: CGFloat, from startX: CGFloat? = nil, to endX: CGFloat? = nil, color: UIColor, lineWidth: CGFloat) {
        cg.saveGState()
        cg.setStrokeColor(color.cgColor)
        cg.setLineWidth(lineWidth)
        cg.move(to: CGPoint(x: startX ?? left, y: lineY))
        cg.addLine(to: CGPoint(x: endX ?? right, y: lineY))
        cg.strokePath()
        cg.restoreGState()
    }

    private func drawLogo(_ branding: ReportData.Branding, in rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        if let name = branding.logoFileName, let image = store.thumbnail(name, maxPixel: 200) {
            cg.saveGState()
            path.addClip()
            UIImage(cgImage: image).draw(in: aspectFill(CGSize(width: image.width, height: image.height), in: rect))
            cg.restoreGState()
        } else {
            Palette.ink.setFill()
            path.fill()
            let initial = String(branding.businessName.prefix(1)).uppercased()
            let font = UIFont.systemFont(ofSize: 20, weight: .bold)
            let size = (initial as NSString).size(withAttributes: [.font: font])
            (initial as NSString).draw(
                at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2),
                withAttributes: [.font: font, .foregroundColor: UIColor.white]
            )
        }
    }

    private func drawPhoto(_ photo: ReportData.Photo, in rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 3)
        cg.saveGState()
        path.addClip()
        if let image = store.thumbnail(photo.fileName, maxPixel: 600) {
            UIImage(cgImage: image).draw(in: aspectFill(CGSize(width: image.width, height: image.height), in: rect))
        } else {
            Palette.placeholder.setFill()
            path.fill()
        }
        cg.restoreGState()
    }

    private func aspectFill(_ size: CGSize, in rect: CGRect) -> CGRect {
        let scale = max(rect.width / size.width, rect.height / size.height)
        let scaled = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: rect.midX - scaled.width / 2, y: rect.midY - scaled.height / 2, width: scaled.width, height: scaled.height)
    }

    /// Draws wrapped text at (x, y or the current cursor) and returns the height used.
    @discardableResult
    private func text(
        _ string: String, _ font: UIFont, _ color: UIColor, x: CGFloat? = nil, y atY: CGFloat? = nil,
        width: CGFloat, align: NSTextAlignment = .left, maxHeight: CGFloat? = nil, kern: CGFloat = 0
    ) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byTruncatingTail
        let attributed = NSAttributedString(string: string, attributes: [
            .font: font, .foregroundColor: color, .paragraphStyle: style, .kern: kern
        ])
        let limit = CGSize(width: width, height: maxHeight ?? .greatestFiniteMagnitude)
        let height = ceil(attributed.boundingRect(with: limit, options: .usesLineFragmentOrigin, context: nil).height)
        attributed.draw(
            with: CGRect(x: x ?? left, y: atY ?? y, width: width, height: height),
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil
        )
        return height
    }
}
