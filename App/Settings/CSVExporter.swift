import Foundation

/// CSV of jobs and receipts (Pro). One row per job, one per receipt.
enum CSVExporter {
    static func csv(for jobs: [Job]) -> String {
        var rows = [["kind", "job", "client", "date", "description", "amount"]]
        let date = Date.ISO8601FormatStyle().year().month().day()
        for job in jobs.sorted(by: { $0.number < $1.number }) {
            rows.append(["job", job.numberLabel, job.clientName, job.startedAt.formatted(date), job.siteAddress, "\(job.totals.total)"])
            for receipt in job.receipts.sorted(by: { $0.purchasedAt < $1.purchasedAt }) {
                rows.append([
                    "receipt", job.numberLabel, job.clientName, receipt.purchasedAt.formatted(date),
                    receipt.merchantName, "\(receipt.total)"
                ])
            }
        }
        return rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    /// RFC 4180 quoting; also neutralizes spreadsheet formulas typed into free-text fields.
    static func escape(_ field: String) -> String {
        var value = field
        if let first = value.first, "=+-@".contains(first) { value = "'" + value }
        guard value.contains(where: { ",\"\n\r".contains($0) }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
