import XCTest

final class FooterLinkTests: XCTestCase {
    func testFooterOpensBrowser() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-demo-settings"]
        app.launch()

        let link = app.descendants(matching: .any)["site-link"].firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 8), "footer link not found")
        link.tap()

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10),
                      "default browser did not open")
    }
}
