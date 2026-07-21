import XCTest

final class CategoryChangeTests: XCTestCase {
    func testCategoryChangePersists() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        // run-unique id: stable across the mid-test relaunch (the change
        // must persist), fresh on the next run (the change must not)
        app.launchArguments = ["-naru-uitest-seed", "category-persist-\(UUID().uuidString)"]
        app.launch()
        app.staticTexts["Charm"].firstMatch.tap()
        let pill = app.buttons["category-pill"].firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 8), "category pill missing")
        XCTAssertTrue(pill.label.contains("Music"), "expected Music, got \(pill.label)")
        pill.tap()
        let reading = app.buttons["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 5), "Reading option missing")
        reading.tap()
        app.terminate()
        app.launch()
        app.staticTexts["Charm"].firstMatch.tap()
        let pill2 = app.buttons["category-pill"].firstMatch
        XCTAssertTrue(pill2.waitForExistence(timeout: 8))
        XCTAssertTrue(pill2.label.contains("Reading"), "did not persist: \(pill2.label)")
    }

    func testContextMenuHasMoveTo() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-uitest-seed", "category-move"]
        app.launch()
        let tile = app.staticTexts["Apple"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 8))
        tile.press(forDuration: 1.1)
        let move = app.buttons["Move to"].firstMatch
        XCTAssertTrue(move.waitForExistence(timeout: 5), "Move to missing from context menu")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "context-menu"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
