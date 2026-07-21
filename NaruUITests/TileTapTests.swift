import XCTest

final class TileTapTests: XCTestCase {
    // tapping the transparent lower-right of a left-column tile must open
    // that tile, not the right-column neighbor (nearest-button fallthrough)
    func testLeftTileEdgeOpensLeftItem() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-uitest-seed", "tile-tap-\(UUID().uuidString)"]
        app.launch()

        // left tile = "What We Owe Our Libraries"; its button label carries
        // the title. Tap its lower-right corner — the strip beside the
        // single-line metadata that used to fall through to "Charm".
        let leftTile = app.buttons.containing(
            NSPredicate(format: "label CONTAINS 'What We Owe'")).firstMatch
        XCTAssertTrue(leftTile.waitForExistence(timeout: 10), "left tile missing")
        leftTile.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.92)).tap()

        // summaries now render on the grid cards themselves, and the grid
        // stays in the accessibility tree behind the sheet — identify the
        // opened item by the detail sheet's category pill instead
        let pill = app.buttons["category-pill"].firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 6),
                      "left item's detail did not open")
        XCTAssertTrue(pill.label.contains("Reading"),
                      "the right neighbor opened instead: \(pill.label)")
    }
}
