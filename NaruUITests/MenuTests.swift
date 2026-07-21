import XCTest

final class MenuTests: XCTestCase {
    func testMenuShowsSettings() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launch()
        let more = app.buttons["more-button"].firstMatch
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        more.tap()
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "Settings item missing from menu")
        settings.tap()
        let theme = app.staticTexts["Theme"].firstMatch
        XCTAssertTrue(theme.waitForExistence(timeout: 5), "Settings sheet did not open")

        let about = app.buttons["About"].firstMatch
        XCTAssertTrue(about.waitForExistence(timeout: 3))
        about.tap()
        let version = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Version'")).firstMatch
        XCTAssertTrue(version.waitForExistence(timeout: 5), "About page did not open")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "about-page"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
