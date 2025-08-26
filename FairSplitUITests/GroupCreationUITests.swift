import XCTest

final class GroupCreationUITests: XCTestCase {
    @MainActor
    func test_addGroup_appearsInList() throws {
        let app = XCUIApplication()
        app.launch()

        // Open Add Group sheet
        let addButton = app.buttons["Add Group"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        addButton.tap()

        // Fill in fields
        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Test Group")

        // Save
        app.buttons["Save"].tap()

        // Verify the new group appears in the list
        XCTAssertTrue(app.staticTexts["Test Group"].waitForExistence(timeout: 2))
    }
}

