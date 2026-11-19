import StoreKitTest
import XCTest

/// App Store screenshots (`bundle exec fastlane screenshots`); devices/languages in fastlane/Snapfile.
/// Uses the DEBUG-only `-closeoutDemoSeed` data. Not MainActor: default isolation would change the XCTestCase inits.
final nonisolated class SnapshotUITests: XCTestCase {
    /// Kept alive for the whole test so the paywall shows the local Products.storekit prices.
    nonisolated(unsafe) private var storeKitSession: SKTestSession?

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        storeKitSession = try Self.makeStoreKitSession()
    }

    /// Attaches App/StoreKit/Products.storekit (the simulator shares the host filesystem). A copy gets a group
    /// display name, which SubscriptionStoreView needs before it shows the plans.
    private static func makeStoreKitSession() throws -> SKTestSession {
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "App/StoreKit/Products.storekit")
        var config = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: source)) as? [String: Any])
        var groups = try XCTUnwrap(config["subscriptionGroups"] as? [[String: Any]])
        for index in groups.indices {
            groups[index]["localizations"] = ["en_US", "vi"].map {
                ["description": "", "displayName": "Closeout Pro", "locale": $0]
            }
        }
        config["subscriptionGroups"] = groups
        let copy = URL.temporaryDirectory.appending(path: "Products-snapshot.storekit")
        try JSONSerialization.data(withJSONObject: config).write(to: copy)
        let session = try SKTestSession(contentsOf: copy)
        session.resetToDefaultState()
        session.disableDialogs = true
        return session
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-closeoutDemoSeed"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Marta Ruiz"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor
    func testCaptureScreenshots() throws {
        var app = launch()
        snapshot("01-jobs")

        app.staticTexts["Marta Ruiz"].tap()
        XCTAssertTrue(app.buttons["previewReportButton"].waitForExistence(timeout: 5))
        sleep(2)
        snapshot("02-job-detail")

        // Scroll the receipt above the bottom bar, then open it (OCR-prefilled editor).
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Home Depot'")).firstMatch.tap()
        sleep(2)
        snapshot("03-receipt")

        app.terminate()
        app = launch()
        app.staticTexts["Marta Ruiz"].tap()
        app.buttons["previewReportButton"].tap()
        XCTAssertTrue(app.buttons["shareReportButton"].waitForExistence(timeout: 10))
        sleep(2)
        snapshot("04-report")

        app.terminate()
        app = launch()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["seeProPlansButton"].waitForExistence(timeout: 5))
        sleep(1)
        snapshot("05-settings")

        app.buttons["seeProPlansButton"].tap()
        sleep(5)
        snapshot("06-paywall")
    }
}
