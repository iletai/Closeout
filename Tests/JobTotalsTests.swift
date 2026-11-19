import Foundation
import SwiftData
import Testing
@testable import Closeout

struct JobTotalsTests {
    private func dec(_ value: String) -> Decimal { Decimal(string: value) ?? 0 }

    @Test func hourlyTotal() {
        let totals = JobTotals(
            pricing: .hourly, hourlyRate: dec("140"), laborHours: 8, fixedPrice: dec("999"), materials: dec("180"),
            receipts: [], mileage: []
        )
        #expect(totals.labor == dec("1120"))
        #expect(totals.total == dec("1300"))
    }

    @Test func fixedTotalIgnoresRateAndHours() {
        let totals = JobTotals(
            pricing: .fixed, hourlyRate: dec("140"), laborHours: 8, fixedPrice: dec("500"), materials: 0,
            receipts: [], mileage: []
        )
        #expect(totals.labor == dec("500"))
    }

    @Test func receiptSumExcludesNonReimbursable() {
        let totals = JobTotals(
            pricing: .fixed, hourlyRate: 0, laborHours: 0, fixedPrice: 0, materials: 0,
            receipts: [(dec("86.40"), true), (dec("93.60"), true), (dec("40"), false)], mileage: []
        )
        #expect(totals.expenses == dec("180.00"))
    }

    @Test func mileageRoundsEachEntryToCents() {
        // 18.4 * 1.20 = 22.08; 3.3 * 0.675 = 2.2275 -> 2.23
        let totals = JobTotals(
            pricing: .fixed, hourlyRate: 0, laborHours: 0, fixedPrice: 0, materials: 0, receipts: [],
            mileage: [(18.4, dec("1.20")), (3.3, dec("0.675"))]
        )
        #expect(totals.mileageCost == dec("24.31"))
    }

    @Test func fractionalHoursKeepDecimalPrecision() {
        let totals = JobTotals(
            pricing: .hourly, hourlyRate: dec("75"), laborHours: 2.5, fixedPrice: 0, materials: 0,
            receipts: [], mileage: []
        )
        #expect(totals.labor == dec("187.50"))
    }

    @Test func jobTotalsCombinesAllParts() throws {
        let container = try AppSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let job = Job()
        job.hourlyRate = dec("140")
        job.laborHours = 8
        job.materialsTotal = dec("180")
        context.insert(job)
        job.receipts.append(Receipt(merchantName: "Home Depot", total: dec("86.40"), currencyCode: "USD"))
        job.mileage.append(MileageEntry(miles: 18.4, ratePerMile: dec("1.20")))
        #expect(job.totals.total == dec("1408.48"))
    }
}

struct ModelTests {
    @Test func cascadeDeleteRemovesChildren() throws {
        let container = try AppSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let job = Job()
        context.insert(job)
        job.photos.append(EvidencePhoto(fileName: "a.jpg"))
        job.photos.append(EvidencePhoto(fileName: "b.jpg"))
        job.receipts.append(Receipt(merchantName: "X", total: 1, currencyCode: "USD"))
        job.mileage.append(MileageEntry(miles: 1, ratePerMile: 1))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<EvidencePhoto>()) == 2)

        context.delete(job)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<EvidencePhoto>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Receipt>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MileageEntry>()) == 0)
    }

    @Test func seedCreatesSingleProfile() throws {
        let container = try AppSchema.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let first = try BusinessProfile.seedIfNeeded(in: context, currencyCode: "GBP")
        let second = try BusinessProfile.seedIfNeeded(in: context, currencyCode: "USD")
        #expect(first === second)
        #expect(try context.fetchCount(FetchDescriptor<BusinessProfile>()) == 1)
        #expect(first.currencyCode == "GBP")
        #expect(first.defaultMileageRate == Decimal(string: "0.45"))
    }
}
