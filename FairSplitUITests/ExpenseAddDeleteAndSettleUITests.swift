import XCTest

final class ExpenseAddDeleteAndSettleUITests: XCTestCase {

    @MainActor
    func test_addExpense_thenDelete_itDisappears() throws {
        let app = XCUIApplication()
        app.launch()

        // Open the seeded group
        app.cells.firstMatch.tap()

        // Add expense
        app.buttons["Add Expense"].tap()
        app.textFields["Title"].tap()
        app.textFields["Title"].typeText("Water")

        let amountField = app.textFields["Amount"]
        amountField.tap()
        amountField.typeText("3")

        app.buttons["Save"].tap()

        // Verify appears
        let newCell = app.staticTexts["Water"]
        XCTAssertTrue(newCell.waitForExistence(timeout: 2))

        // Delete it
        let cell = app.cells.containing(.staticText, identifier: "Water").element
        cell.swipeLeft()
        cell.buttons["Delete"].tap()

        // Verify removed
        XCTAssertFalse(newCell.waitForExistence(timeout: 1))
    }

    @MainActor
    func test_settleUp_recordsSettlementAndShowsAlert() throws {
        let app = XCUIApplication()
        app.launch()

        // Open the seeded group
        app.cells.firstMatch.tap()

        // Open Settle Up
        app.navigationBars.buttons["Settle Up"].tap()

        // If there are suggestions, record
        let recordButton = app.buttons["Record Settlement"]
        if recordButton.waitForExistence(timeout: 2) && recordButton.isEnabled {
            recordButton.tap()
            XCTAssertTrue(app.alerts["Settlement recorded"].waitForExistence(timeout: 2))
            app.alerts.buttons["OK"].tap()
        } else {
            // Otherwise, we're all settled; the empty state should exist
            XCTAssertTrue(app.staticTexts["You're all settled!"].exists)
        }
    }
}

