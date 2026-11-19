import Foundation

/// Pure money math for a job (no SwiftData). Decimal only; every line is rounded to cents.
struct JobTotals: Equatable, Sendable {
    let labor: Decimal
    let materials: Decimal
    let expenses: Decimal
    let mileageCost: Decimal
    var total: Decimal { labor + materials + expenses + mileageCost }

    init(
        pricing: PricingMode, hourlyRate: Decimal, laborHours: Double, fixedPrice: Decimal, materials: Decimal,
        receipts: [(total: Decimal, reimbursable: Bool)], mileage: [(miles: Double, ratePerMile: Decimal)]
    ) {
        labor = (pricing == .hourly ? hourlyRate * Decimal.exact(laborHours) : fixedPrice).roundedToCents
        self.materials = materials
        expenses = receipts.filter(\.reimbursable).reduce(0) { $0 + $1.total }
        mileageCost = mileage.reduce(0) { $0 + (Decimal.exact($1.miles) * $1.ratePerMile).roundedToCents }
    }
}

extension Decimal {
    /// Double -> Decimal through the shortest decimal string, so 18.4 stays 18.4 (not 18.39999...).
    static func exact(_ value: Double) -> Decimal {
        Decimal(string: "\(value)") ?? Decimal(value)
    }

    var roundedToCents: Decimal {
        var result = Decimal()
        var source = self
        NSDecimalRound(&result, &source, 2, .plain)
        return result
    }
}
