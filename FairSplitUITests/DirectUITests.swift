import XCTest

final class DirectUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func test_directTab_emptyStatesAndActionsVisible() {
        // Go to Direct tab
        XCTAssertTrue(app.tabBars.buttons["Direct"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Direct"].tap()

        // Navigation title
        XCTAssertTrue(app.navigationBars["Direct"].waitForExistence(timeout: 3))

        // Top actions should be present
        XCTAssertTrue(app.buttons["Add Direct Expense"].exists)
        XCTAssertTrue(app.buttons["Add Contact"].exists)

        // Section headers
        XCTAssertTrue(app.staticTexts["Balances"].exists)
        XCTAssertTrue(app.staticTexts["Contacts"].exists)

        // Empty states
        XCTAssertTrue(app.staticTexts["No direct expenses"].exists)
        XCTAssertTrue(app.staticTexts["No Contacts Yet"].exists)

        // "Recent" section should not appear when there are no expenses
        XCTAssertFalse(app.staticTexts["Recent"].exists)

        // Attach a screenshot for quick visual verification in CI logs
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "Direct-Empty"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test_directTab_populatedShowsRecent() {
        // Go to Direct tab
        XCTAssertTrue(app.tabBars.buttons["Direct"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Direct"].tap()

        // Add two contacts
        app.buttons["Add Contact"].tap()
        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap(); nameField.typeText("Alice")
        app.buttons["Save"].tap()

        app.buttons["Add Contact"].tap()
        let nameField2 = app.textFields["Name"]
        XCTAssertTrue(nameField2.waitForExistence(timeout: 2))
        nameField2.tap(); nameField2.typeText("Bob")
        app.buttons["Save"].tap()

        // Add a direct expense between Alice and Bob
        app.buttons["Add Direct Expense"].tap()
        XCTAssertTrue(app.navigationBars["New Direct Expense"].waitForExistence(timeout: 2))
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap(); titleField.typeText("Coffee")
        let amountField = app.textFields["Amount"]
        amountField.tap(); amountField.typeText("5.00")

        // Pickers may be navigation link style; open and choose
        app.staticTexts["Payer"].tap()
        XCTAssertTrue(app.staticTexts["Alice"].waitForExistence(timeout: 2))
        app.staticTexts["Alice"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back

        app.staticTexts["Other"].tap()
        XCTAssertTrue(app.staticTexts["Bob"].waitForExistence(timeout: 2))
        app.staticTexts["Bob"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back

        app.buttons["Save"].tap()

        // Now Recent section should appear with the new expense
        XCTAssertTrue(app.staticTexts["Recent"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Coffee"].exists)

        // Attach a screenshot to record the populated state
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "Direct-Populated"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
