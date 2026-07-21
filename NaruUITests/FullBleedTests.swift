import XCTest

final class FullBleedTests: XCTestCase {
    // every third loadable-thumbnail save renders full-bleed with the title
    // overlaid on the image; a save that CLAIMS a thumbnail with no JPEG on
    // disk must fall back to a text card, not an empty image
    func testFullBleedRendersAndMissingThumbnailFallsBack() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-uitest-seed", "full-bleed-\(UUID().uuidString)"]
        app.launch()

        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        scroll.swipeUp()

        let fullBleedTitle = app.staticTexts["The deep sea is darker than you think"]
        XCTAssertTrue(fullBleedTitle.waitForExistence(timeout: 6),
                      "full-bleed card's overlaid title missing")

        scroll.swipeUp()
        // text cards show their summary on the grid; image cards never do —
        // the summary's presence proves the text-card fallback
        let fallbackSummary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'exactly the point'")).firstMatch
        XCTAssertTrue(fallbackSummary.waitForExistence(timeout: 6),
                      "missing-thumbnail save should fall back to a text card")
    }
}
