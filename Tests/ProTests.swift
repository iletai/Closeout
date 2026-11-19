import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import Closeout

/// Purchase flow against the local `Products.storekit`. SKTestSession only attaches when Xcode installed the app
/// "for development" (Cmd-U); under plain `xcodebuild test` storekitd refuses it, so these tests cancel themselves.
@Suite(.serialized)
struct StoreKitPurchaseTests {
    private func makeSession() async throws -> SKTestSession {
        let url = try #require(Bundle.main.url(forResource: "Products", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        let products = try await Product.products(for: [Store.lifetimeID])
        if products.isEmpty { try Test.cancel("StoreKit test session is not attached (app not installed for development)") }
        return session
    }

    @Test func lifetimePurchaseLiftsPhotoLimitAndSurvivesRestore() async throws {
        let session = try await makeSession()
        defer { withExtendedLifetime(session) {} }
        #expect(await Store.hasPro() == false)
        #expect(!PhotoQuota.canAdd(5, existing: 0, isPro: await Store.hasPro()))

        try await session.buyProduct(productIdentifier: Store.lifetimeID)
        #expect(await Store.hasPro())
        #expect(PhotoQuota.canAdd(50, existing: 4, isPro: await Store.hasPro()))

        // Restore Purchases = AppStore.sync(); the entitlement must still be there afterwards.
        try await AppStore.sync()
        #expect(await Store.hasPro())
    }

    @Test func yearlySubscriptionGrantsPro() async throws {
        let session = try await makeSession()
        defer { withExtendedLifetime(session) {} }
        try await session.buyProduct(productIdentifier: "\(AppConfiguration.bundleIdentifier).pro.yearly")
        #expect(await Store.hasPro())
    }
}

private struct StoreConfigLocalization: Decodable { let locale: String, displayName: String, description: String }
private struct StoreConfigOffer: Decodable { let paymentMode: String, subscriptionPeriod: String }
private struct StoreConfigProduct: Decodable {
    let productID: String, displayPrice: String
    let localizations: [StoreConfigLocalization]
    let introductoryOffer: StoreConfigOffer?
}
private struct StoreConfigGroup: Decodable { let id: String, subscriptions: [StoreConfigProduct] }
private struct StoreConfigFile: Decodable {
    let products: [StoreConfigProduct]
    let subscriptionGroups: [StoreConfigGroup]
}

/// Static checks of the StoreKit configuration file: these run everywhere.
struct StoreConfigurationTests {
    private func load() throws -> StoreConfigFile {
        let url = try #require(Bundle.main.url(forResource: "Products", withExtension: "storekit"))
        return try JSONDecoder().decode(StoreConfigFile.self, from: Data(contentsOf: url))
    }

    @Test func offersTwoProductsPricedPerPlan() throws {
        let config = try load()
        let lifetime = try #require(config.products.first)
        let group = try #require(config.subscriptionGroups.first)
        #expect(config.products.count == 1 && group.subscriptions.count == 1, "No weekly/monthly plan")
        let yearly = try #require(group.subscriptions.first)
        #expect(lifetime.productID == Store.lifetimeID && lifetime.displayPrice == "29.99")
        #expect(yearly.productID == "\(AppConfiguration.bundleIdentifier).pro.yearly" && yearly.displayPrice == "14.99")
        #expect(yearly.introductoryOffer?.paymentMode == "free" && yearly.introductoryOffer?.subscriptionPeriod == "P1W")
        #expect(group.id == Store.groupID, "StoreKit group id must match SUBSCRIPTION_GROUP_ID in Dev.xcconfig")
    }

    @Test func localizedForEnglishAndVietnameseWithinAppStoreLimits() throws {
        let config = try load()
        let products = config.products + config.subscriptionGroups.flatMap(\.subscriptions)
        for product in products {
            #expect(Set(product.localizations.map(\.locale)) == ["en_US", "vi"])
            for localization in product.localizations {
                #expect(localization.displayName.count <= 35, "\(localization.displayName)")
                #expect(localization.description.count <= 55, "\(localization.description)")
            }
        }
    }
}

struct CSVExporterTests {
    @Test func escapesCommasQuotesAndFormulas() {
        #expect(CSVExporter.escape("Smith, John") == "\"Smith, John\"")
        #expect(CSVExporter.escape("5\" pipe") == "\"5\"\" pipe\"")
        #expect(CSVExporter.escape("=SUM(A1)") == "'=SUM(A1)")
        #expect(CSVExporter.escape("plain") == "plain")
    }
}
