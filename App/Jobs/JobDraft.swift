import Foundation

/// Editable copy of a job's fields; Cancel simply drops it.
struct JobDraft {
    var title = ""
    var clientName = ""
    var clientContact = ""
    var siteAddress = ""
    var startedAt = Date.now
    var pricing = PricingMode.hourly
    var hourlyRate = Decimal.zero
    var laborHours = 0.0
    var fixedPrice = Decimal.zero
    var materialsTotal = Decimal.zero
    var notes = ""

    init(defaultHourlyRate: Decimal = 0) {
        hourlyRate = defaultHourlyRate
    }

    init(job: Job) {
        title = job.title
        clientName = job.clientName
        clientContact = job.clientContact
        siteAddress = job.siteAddress
        startedAt = job.startedAt
        pricing = job.pricing
        hourlyRate = job.hourlyRate
        laborHours = job.laborHours
        fixedPrice = job.fixedPrice
        materialsTotal = job.materialsTotal
        notes = job.notes
    }

    var isValid: Bool { !clientName.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Labor + materials only; receipts and mileage are added later on the job.
    var estimatedTotal: Decimal {
        JobTotals(
            pricing: pricing, hourlyRate: hourlyRate, laborHours: laborHours, fixedPrice: fixedPrice,
            materials: materialsTotal, receipts: [], mileage: []
        ).total
    }

    func apply(to job: Job) {
        job.title = title
        job.clientName = clientName.trimmingCharacters(in: .whitespaces)
        job.clientContact = clientContact
        job.siteAddress = siteAddress
        job.startedAt = startedAt
        job.pricing = pricing
        job.hourlyRate = hourlyRate
        job.laborHours = laborHours
        job.fixedPrice = fixedPrice
        job.materialsTotal = materialsTotal
        job.notes = notes
        job.updatedAt = .now
    }
}
