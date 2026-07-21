import XCTest

final class TileTapTests: XCTestCase {
    // tapping the transparent lower-right of a left-column tile must open
    // that tile, not the right-column neighbor (nearest-button fallthrough)
    func testLeftTileEdgeOpensLeftItem() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launch()

        // left tile = "What We Owe Our Libraries"; its button label carries
        // the title. Tap its lower-right corner — the strip beside the
        // single-line metadata that used to fall through to "Charm".
        let leftTile = app.buttons.containing(
            NSPredicate(format: "label CONTAINS 'What We Owe'")).firstMatch
        XCTAssertTrue(leftTile.waitForExistence(timeout: 10), "left tile missing")
        leftTile.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.92)).tap()

        // each item's summary is unique and appears only in its own sheet
        let leftSummary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Public libraries quietly'")).firstMatch
        let rightSummary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Clairo'")).firstMatch
        XCTAssertTrue(leftSummary.waitForExistence(timeout: 6),
                      "left item's detail did not open")
        XCTAssertFalse(rightSummary.exists,
                       "the right neighbor opened instead")
    }
}
