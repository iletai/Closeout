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
}
