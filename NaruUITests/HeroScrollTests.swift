import XCTest

// Visual check: after the hero collapses to its floor it should ride up
// with the content (scroll off-screen), not stay pinned with text sliding
// underneath. Captures a drag sequence as attachments for review.
final class HeroScrollTests: XCTestCase {
    func testHeroLiftsAfterCollapse() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-demo-detail-long", "-naru-demo-large"]
        app.launch()

        func snap(_ name: String) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            a.name = name
            a.lifetime = .keepAlways
            add(a)
        }

        sleep(1)
        snap("00-open")

        // scroll the content in small steps to watch the hero collapse to
        // its floor and then ride up and off with the text. Start the drag
        // low in the sheet and end high so it registers as content scroll.
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.80))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.74))
        for i in 1...14 {
            start.press(forDuration: 0.02, thenDragTo: end)
            usleep(500_000)
            snap(String(format: "%02d-scroll", i))
        }
    }
}
