import CoreGraphics
import Foundation

enum ReportPageSize: Sendable {
    case letter, a4

    var size: CGSize {
        switch self {
        case .letter: CGSize(width: 612, height: 792)
        case .a4: CGSize(width: 595, height: 842)
        }
    }

    /// US and Canada print on Letter, everyone else on A4.
    static func forRegion(_ region: Locale.Region? = Locale.current.region) -> ReportPageSize {
        region == .unitedStates || region == .canada ? .letter : .a4
    }
}

struct ReportOptions: Equatable, Sendable {
    var includeReceipts = true
    var includeMileage = true
}

/// Value snapshot of everything the PDF shows, so rendering can run off the main actor.
struct ReportData: Sendable {
    struct Branding: Sendable {
        let businessName: String
        let contactLine: String
        let logoFileName: String?
    }

    struct Photo: Sendable {
        let fileName: String
        let label: String
    }

    struct ReceiptRow: Sendable {
        let date: Date
        let merchant: String
        let amount: Decimal
    }

    struct MileageRow: Sendable {
        let route: String
        let miles: Double
        let cost: Decimal
    }

    /// nil on the free plan: the report is unbranded and carries a "Made with Closeout" footer.
    var branding: Branding?
    var jobNumber: String
    var dateRange: String
    var title: String
    var notes: String
    var clientName: String
    var clientContact: String
    var siteAddress: String
    var photos: [Photo]
    var receipts: [ReceiptRow]
    var mileage: [MileageRow]
    var totals: JobTotals
    var laborHours: Double?
    var currencyCode: String
    var footerNote: String
    var includeSignature: Bool
    var pageSize: ReportPageSize
    var locale: Locale = .current

    @MainActor
    init(job: Job, profile: BusinessProfile?, isPro: Bool, options: ReportOptions, pageSize: ReportPageSize = .forRegion()) {
        let contact = [profile?.phone, profile?.email].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        branding = isPro ? Branding(
            businessName: profile?.businessName ?? "", contactLine: contact, logoFileName: profile?.logoFileName
        ) : nil
        jobNumber = job.numberLabel
        dateRange = job.dateRangeText
        title = job.title
        notes = job.notes
        clientName = job.clientName
        clientContact = job.clientContact
        siteAddress = job.siteAddress
        photos = job.photos.sorted { $0.capturedAt < $1.capturedAt }
            .map { Photo(fileName: $0.fileName, label: $0.caption.isEmpty ? $0.kindRaw : $0.caption) }
        receipts = options.includeReceipts
            ? job.receipts.filter(\.isReimbursable).sorted { $0.purchasedAt < $1.purchasedAt }
                .map { ReceiptRow(date: $0.purchasedAt, merchant: $0.merchantName, amount: $0.total) }
            : []
        mileage = options.includeMileage
            ? job.mileage.sorted { $0.date < $1.date }.map { MileageRow(route: $0.routeText, miles: $0.miles, cost: $0.cost) }
            : []
        // Excluded sections also drop out of the totals so the page adds up.
        var totalsJob = job.totals
        if !options.includeReceipts || !options.includeMileage {
            totalsJob = JobTotals(
                pricing: job.pricing, hourlyRate: job.hourlyRate, laborHours: job.laborHours, fixedPrice: job.fixedPrice,
                materials: job.materialsTotal,
                receipts: options.includeReceipts ? job.receipts.map { ($0.total, $0.isReimbursable) } : [],
                mileage: options.includeMileage ? job.mileage.map { ($0.miles, $0.ratePerMile) } : []
            )
        }
        totals = totalsJob
        laborHours = job.pricing == .hourly ? job.laborHours : nil
        currencyCode = profile?.currencyCode ?? "USD"
        footerNote = isPro ? (profile?.reportFooterNote ?? "") : ""
        includeSignature = profile?.includeSignatureLine ?? true
        self.pageSize = pageSize
    }

    init(
        branding: Branding? = nil, jobNumber: String, dateRange: String = "", title: String = "", notes: String = "",
        clientName: String, clientContact: String = "", siteAddress: String = "", photos: [Photo] = [],
        receipts: [ReceiptRow] = [], mileage: [MileageRow] = [], totals: JobTotals, laborHours: Double? = nil,
        currencyCode: String = "USD", footerNote: String = "", includeSignature: Bool = true,
        pageSize: ReportPageSize = .letter
    ) {
        self.branding = branding
        self.jobNumber = jobNumber
        self.dateRange = dateRange
        self.title = title
        self.notes = notes
        self.clientName = clientName
        self.clientContact = clientContact
        self.siteAddress = siteAddress
        self.photos = photos
        self.receipts = receipts
        self.mileage = mileage
        self.totals = totals
        self.laborHours = laborHours
        self.currencyCode = currencyCode
        self.footerNote = footerNote
        self.includeSignature = includeSignature
        self.pageSize = pageSize
    }
}
