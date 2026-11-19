import Foundation
import SwiftData

@Model
final class Job {
    var id = UUID()
    /// Sequential number shown as "#CL-0142"; assigned by `JobService.create`.
    var number = 0
    var title = ""
    var clientName = ""
    var clientContact = ""
    var siteAddress = ""
    var startedAt = Date.now
    var closedAt: Date?
    var statusRaw = JobStatus.open.rawValue
    var pricingRaw = PricingMode.hourly.rawValue
    var hourlyRate = Decimal.zero
    var laborHours = 0.0
    var fixedPrice = Decimal.zero
    var materialsTotal = Decimal.zero
    var notes = ""
    var createdAt = Date.now
    var updatedAt = Date.now

    @Relationship(deleteRule: .cascade, inverse: \EvidencePhoto.job) var photos: [EvidencePhoto] = []
    @Relationship(deleteRule: .cascade, inverse: \Receipt.job) var receipts: [Receipt] = []
    @Relationship(deleteRule: .cascade, inverse: \MileageEntry.job) var mileage: [MileageEntry] = []

    init() {}

    var status: JobStatus {
        get { JobStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    var pricing: PricingMode {
        get { PricingMode(rawValue: pricingRaw) ?? .hourly }
        set { pricingRaw = newValue.rawValue }
    }

    var totals: JobTotals {
        JobTotals(
            pricing: pricing, hourlyRate: hourlyRate, laborHours: laborHours, fixedPrice: fixedPrice,
            materials: materialsTotal,
            receipts: receipts.map { ($0.total, $0.isReimbursable) },
            mileage: mileage.map { ($0.miles, $0.ratePerMile) }
        )
    }

    /// "CL-0142" style label.
    var numberLabel: String { String(format: "#CL-%04d", number) }
}

@Model
final class EvidencePhoto {
    var id = UUID()
    /// File in `EvidenceStore` directory (never stored in the database).
    var fileName = ""
    var caption = ""
    var capturedAt = Date.now
    var kindRaw = EvidenceKind.site.rawValue
    var job: Job?

    init(fileName: String, caption: String = "", kind: EvidenceKind = .site) {
        self.fileName = fileName
        self.caption = caption
        self.kindRaw = kind.rawValue
    }

    var kind: EvidenceKind {
        get { EvidenceKind(rawValue: kindRaw) ?? .site }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class Receipt {
    var id = UUID()
    var merchantName = ""
    var total = Decimal.zero
    var currencyCode = "USD"
    var purchasedAt = Date.now
    var fileName: String?
    var ocrConfidence = 0.0
    var isReimbursable = true
    var job: Job?

    init(merchantName: String, total: Decimal, currencyCode: String, purchasedAt: Date = .now,
         fileName: String? = nil, ocrConfidence: Double = 0, isReimbursable: Bool = true) {
        self.merchantName = merchantName
        self.total = total
        self.currencyCode = currencyCode
        self.purchasedAt = purchasedAt
        self.fileName = fileName
        self.ocrConfidence = ocrConfidence
        self.isReimbursable = isReimbursable
    }
}

@Model
final class MileageEntry {
    var id = UUID()
    var date = Date.now
    var miles = 0.0
    var startLabel = ""
    var endLabel = ""
    var ratePerMile = Decimal.zero
    var job: Job?

    init(date: Date = .now, miles: Double, startLabel: String = "", endLabel: String = "", ratePerMile: Decimal) {
        self.date = date
        self.miles = miles
        self.startLabel = startLabel
        self.endLabel = endLabel
        self.ratePerMile = ratePerMile
    }
}
