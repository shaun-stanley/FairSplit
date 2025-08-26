import XCTest

final class TabBarUITests: XCTestCase {
    @MainActor
    func test_tabs_exist_and_switch() throws {
        let app = XCUIApplication()
        app.launch()

        // Ensure Groups tab exists
        XCTAssertTrue(app.tabBars.buttons["Groups"].waitForExistence(timeout: 2))

        // Switch to Reports
        app.tabBars.buttons["Reports"].tap()
        XCTAssertTrue(app.navigationBars["Reports"].waitForExistence(timeout: 2))

        // Switch to Settings
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }
}

