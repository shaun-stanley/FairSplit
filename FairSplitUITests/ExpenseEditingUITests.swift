import XCTest

final class ExpenseEditingUITests: XCTestCase {
    @MainActor
    func test_editExpense_updatesTitle() throws {
        let app = XCUIApplication()
        app.launch()

        // Open the seeded group
        app.cells.firstMatch.tap()

        // Edit the first expense
        let expenseCell = app.cells.containing(.staticText, identifier: "Groceries").element
        expenseCell.swipeLeft()
        expenseCell.buttons["Edit"].tap()

        let titleField = app.textFields["Title"]
        titleField.clearAndEnterText("Snacks")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Snacks"].waitForExistence(timeout: 1))
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()
        let current = (value as? String) ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
        typeText(deleteString)
        typeText(text)
    }
}
