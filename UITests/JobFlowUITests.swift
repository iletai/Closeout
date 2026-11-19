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
}
