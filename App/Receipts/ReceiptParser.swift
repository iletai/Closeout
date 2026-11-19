import Foundation

struct ParsedReceipt: Equatable, Sendable {
    var merchant: String?
    var total: Decimal?
    var date: Date?
}

/// Pulls merchant, total and date out of OCR text lines (top to bottom). Pure and heuristic:
/// results are always shown to the user as editable fields.
enum ReceiptParser {
    private static let totalKeywords = ["grand total", "amount due", "balance due", "total due", "tổng cộng", "tổng", "total"]
    private static let excludedKeywords = ["subtotal", "sub total", "sub-total", "total savings", "total tax"]
    private static var amountPattern: Regex<Substring> { /\d+(?:[.,]\d{3})*[.,]\d{2}(?!\d)/ }

    static func parse(lines: [String], now: Date = .now) -> ParsedReceipt {
        ParsedReceipt(merchant: merchant(in: lines), total: total(in: lines), date: date(in: lines, now: now))
    }

    private static func merchant(in lines: [String]) -> String? {
        lines.prefix(6)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { line in
                let letters = line.filter(\.isLetter).count
                return letters >= 3 && Double(letters) / Double(line.count) >= 0.5
            }
    }

    private static func total(in lines: [String]) -> Decimal? {
        var keywordTotal: Decimal?
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            guard totalKeywords.contains(where: lower.contains),
                  !excludedKeywords.contains(where: lower.contains) else { continue }
            // The amount is on the same line or the next one (two-column receipts).
            let candidates = [line] + (index + 1 < lines.count ? [lines[index + 1]] : [])
            if let amount = candidates.lazy.compactMap({ amounts(in: $0).last }).first { keywordTotal = amount }
        }
        return keywordTotal ?? lines.flatMap(amounts(in:)).max()
    }

    private static func amounts(in line: String) -> [Decimal] {
        line.matches(of: amountPattern).compactMap { normalize(String($0.output)) }
    }

    /// "1,234.56", "1.234,56" and "86,40" all become Decimals; the last separator is the decimal point.
    private static func normalize(_ raw: String) -> Decimal? {
        let cleaned = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard let separator = cleaned.lastIndex(where: { $0 == "." || $0 == "," }) else { return Decimal(string: cleaned) }
        let integer = cleaned[..<separator].filter(\.isNumber)
        let fraction = cleaned[cleaned.index(after: separator)...]
        return Decimal(string: "\(integer).\(fraction)")
    }

    private static func date(in lines: [String], now: Date) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let text = lines.joined(separator: "\n")
        let earliest = Calendar.current.date(byAdding: .year, value: -15, to: now) ?? .distantPast
        let latest = now.addingTimeInterval(86_400)
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap(\.date)
            .first { $0 >= earliest && $0 <= latest }
    }
}
