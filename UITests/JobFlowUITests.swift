import XCTest

/// Not MainActor: default isolation would change the XCTestCase inits, which are nonisolated.
final nonisolated class JobFlowUITests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateJobAppearsInList() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-closeoutResetData"]
        app.launch()

        app.buttons["logFirstJobButton"].tap()
        let client = app.textFields["clientNameField"]
        XCTAssertTrue(client.waitForExistence(timeout: 5))
        client.tap()
        client.typeText("Marta Ruiz")
        app.buttons["saveJobButton"].tap()

        // Lands on Job Detail, then back to the list.
        XCTAssertTrue(app.staticTexts["Marta Ruiz"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Marta Ruiz"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "jobs-list"
        shot.lifetime = .keepAlways
        add(shot)

        // Persistence: relaunch without the reset flag.
        app.terminate()
        let relaunched = XCUIApplication()
        relaunched.launch()
        XCTAssertTrue(relaunched.staticTexts["Marta Ruiz"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddTwoPhotosPersistAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-closeoutResetData", "-closeoutUITesting"]
        app.launch()

        app.buttons["logFirstJobButton"].tap()
        let client = app.textFields["clientNameField"]
        XCTAssertTrue(client.waitForExistence(timeout: 5))
        client.tap()
        client.typeText("Photo Client")
        app.buttons["saveJobButton"].tap()

        XCTAssertTrue(app.staticTexts["Photo Client"].waitForExistence(timeout: 5))
        app.buttons["Add"].firstMatch.tap()
        let sample = app.buttons["addSamplePhotoButton"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        sample.tap()
        sample.tap()
        app.buttons["saveEvidenceButton"].tap()

        let thumbs = app.buttons.matching(identifier: "evidenceThumb")
        XCTAssertTrue(thumbs.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(thumbs.count, 2)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "job-detail-evidence"
        shot.lifetime = .keepAlways
        add(shot)

        app.terminate()
        let relaunched = XCUIApplication()
        relaunched.launchArguments += ["-closeoutUITesting"]
        relaunched.launch()
        relaunched.staticTexts["Photo Client"].tap()
        XCTAssertTrue(relaunched.buttons.matching(identifier: "evidenceThumb").firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(relaunched.buttons.matching(identifier: "evidenceThumb").count, 2)
    }

    @MainActor
    func testManualReceiptAndMileageAppearOnJob() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-closeoutResetData", "-closeoutUITesting"]
        app.launch()

        app.buttons["logFirstJobButton"].tap()
        let client = app.textFields["clientNameField"]
        XCTAssertTrue(client.waitForExistence(timeout: 5))
        client.tap()
        client.typeText("Ledger Client")
        app.buttons["saveJobButton"].tap()
        XCTAssertTrue(app.staticTexts["Ledger Client"].waitForExistence(timeout: 5))

        // Receipt entered by hand (OCR needs a real camera).
        app.buttons["Scan"].tap()
        app.buttons["enterReceiptManuallyButton"].tap()
        let merchant = app.textFields["receiptMerchantField"]
        XCTAssertTrue(merchant.waitForExistence(timeout: 5))
        merchant.tap()
        merchant.typeText("Home Depot")
        app.buttons["saveReceiptButton"].tap()
        XCTAssertTrue(app.buttons["Home Depot"].waitForExistence(timeout: 5)
            || app.staticTexts["Home Depot"].waitForExistence(timeout: 5))

        // Mileage
        app.buttons.matching(NSPredicate(format: "label == 'Add'")).element(boundBy: 1).tap()
        let miles = app.textFields["mileageMilesField"]
        XCTAssertTrue(miles.waitForExistence(timeout: 5))
        miles.tap()
        miles.typeText("18.4")
        app.buttons["saveMileageButton"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '18.4 mi'")).firstMatch
            .waitForExistence(timeout: 5) || app.buttons.matching(NSPredicate(format: "label CONTAINS '18.4 mi'")).firstMatch
            .waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "job-detail-receipt-mileage"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testCreateJobThenPreviewAndExportReport() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-closeoutResetData", "-closeoutUITesting"]
        app.launch()

        app.buttons["logFirstJobButton"].tap()
        let client = app.textFields["clientNameField"]
        XCTAssertTrue(client.waitForExistence(timeout: 5))
        client.tap()
        client.typeText("Report Client")
        app.buttons["saveJobButton"].tap()

        app.buttons["previewReportButton"].tap()
        XCTAssertTrue(app.staticTexts["Page 1 of 1"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["shareReportButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["exportReportButton"].isEnabled)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "report-preview"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testSettingsShowsFreePlanAndOpensPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-closeoutResetData"]
        app.launch()

        // Settings is reachable from the empty Jobs screen.
        app.buttons["settingsButton"].tap()
        let pro = app.buttons["seeProPlansButton"]
        XCTAssertTrue(pro.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["FREE PLAN"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "settings"
        shot.lifetime = .keepAlways
        add(shot)

        pro.tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))
        let paywall = XCTAttachment(screenshot: app.screenshot())
        paywall.name = "paywall"
        paywall.lifetime = .keepAlways
        add(paywall)
    }
}
