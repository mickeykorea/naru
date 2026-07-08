import XCTest

final class ShareFlowTests: XCTestCase {

    func testShareSheetToNaru() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-demo-share"]
        app.launch()

        // share sheet rows are exposed as cells labeled by app name
        let naruCell = app.cells["Naru"].firstMatch
        let naruAny = app.descendants(matching: .any).matching(identifier: "Naru").element(boundBy: 0)
        if naruCell.waitForExistence(timeout: 12) {
            naruCell.tap()
        } else if naruAny.waitForExistence(timeout: 4) {
            naruAny.tap()
        } else {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "share-sheet"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("Naru not present in share sheet")
            return
        }

        let title = app.staticTexts["Save to Naru"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "extension UI did not load")

        let reads = app.buttons["Reads"]
        XCTAssertTrue(reads.waitForExistence(timeout: 5), "category chips missing")
        reads.tap()

        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: save)
        waitForExpectations(timeout: 15)

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "extension-ui"
        shot.lifetime = .keepAlways
        add(shot)

        save.tap()
        sleep(2)

        // fresh launch must show the shared item persisted via the app group
        app.terminate()
        let clean = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        clean.launch()
        let savedTile = clean.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'apple.com'")).firstMatch
        XCTAssertTrue(savedTile.waitForExistence(timeout: 10), "shared item not in archive")

        let appShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        appShot.name = "app-after-share"
        appShot.lifetime = .keepAlways
        add(appShot)
    }
}
