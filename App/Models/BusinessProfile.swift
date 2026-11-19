import Foundation
import SwiftData

/// Single row, created on first launch via `seedIfNeeded`.
@Model
final class BusinessProfile {
    var businessName = ""
    var ownerName = ""
    var phone = ""
    var email = ""
    var logoFileName: String?
    var currencyCode = "USD"
    var defaultHourlyRate = Decimal.zero
    var defaultMileageRate = Decimal.zero
    var reportFooterNote = ""
    var includeSignatureLine = true

    init(currencyCode: String) {
        self.currencyCode = currencyCode
        self.defaultMileageRate = Self.standardMileageRate(for: currencyCode)
    }

    /// Starting per-mile rate by currency (approximate tax-authority rates); only Pro can change it.
    static func standardMileageRate(for currencyCode: String) -> Decimal {
        switch currencyCode {
        case "GBP": Decimal(string: "0.45") ?? 0
        case "CAD": Decimal(string: "0.72") ?? 0
        case "AUD": Decimal(string: "0.88") ?? 0
        default: Decimal(string: "0.70") ?? 0
        }
    }

    /// Returns the existing profile or inserts one with the device currency.
    @discardableResult
    static func seedIfNeeded(in context: ModelContext, currencyCode: String? = nil) throws -> BusinessProfile {
        if let existing = try context.fetch(FetchDescriptor<BusinessProfile>()).first { return existing }
        let profile = BusinessProfile(currencyCode: currencyCode ?? Locale.current.currency?.identifier ?? "USD")
        context.insert(profile)
        try context.save()
        return profile
    }
}
