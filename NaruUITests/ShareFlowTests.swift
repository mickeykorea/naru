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
        // metadata shows the short brand name ("apple · 2w"), not the domain
        let savedTile = clean.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'apple'")).firstMatch
        XCTAssertTrue(savedTile.waitForExistence(timeout: 10), "shared item not in archive")

        let appShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        appShot.name = "app-after-share"
        appShot.lifetime = .keepAlways
        add(appShot)
    }
}

final class CategoryPagingTests: XCTestCase {

    func testSwipePagesBetweenCategories() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-uitest-seed", "paging-\(UUID().uuidString)"]
        app.launch()

        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))

        // "All" shows the spotify item; first swipe left lands on Reads
        let spotifyMeta = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'spotify'")).firstMatch
        XCTAssertTrue(spotifyMeta.waitForExistence(timeout: 5), "expected All tab content")

        scroll.swipeLeft()
        sleep(1)
        let diag = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        diag.name = "after-swipe-left"
        diag.lifetime = .keepAlways
        add(diag)
        XCTAssertFalse(spotifyMeta.exists, "Reads should not contain the spotify item")

        scroll.swipeRight()
        sleep(1)
        XCTAssertTrue(spotifyMeta.waitForExistence(timeout: 5), "swipe right should return to All")

        // leftmost boundary: another right swipe must not crash or change anything
        scroll.swipeRight()
        sleep(1)
        XCTAssertTrue(spotifyMeta.exists)
    }
}

final class NoteTests: XCTestCase {

    func testNotePersistsAcrossSheetOpens() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        // run-unique: survives the mid-test relaunch, resets next run
        app.launchArguments = ["-naru-uitest-seed", "note-\(UUID().uuidString)"]
        app.launch()

        let tile = app.staticTexts["Apple"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        // the note field is the sheet's only text field; don't match on the
        // placeholder — it disappears once a note exists
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 8), "note field missing in detail sheet")
        field.tap()
        app.typeText("zebra note 42")

        // full relaunch: stronger persistence guarantee than sheet
        // round-tripping, and it avoids XCUITest sheet-dismissal flakiness
        sleep(1)
        app.terminate()
        app.launch()
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        let saved = app.textFields.matching(
            NSPredicate(format: "value CONTAINS 'zebra note 42'")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 8), "note did not persist")
    }
}


final class HeroCollapseTests: XCTestCase {

    func testHeroShrinksWithScrollAndFloors() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-demo-detail", "-naru-demo-large",
                               "-naru-uitest-seed", "hero-\(UUID().uuidString)"]
        app.launch()

        let hero = app.descendants(matching: .any)
            .matching(identifier: "detail-hero").firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "hero missing")
        let full = hero.frame.height
        XCTAssertGreaterThan(full, 200, "hero should start near full height")

        // drag from low on the screen: a center swipe can start on the
        // pinned hero overlay (tall thumbnails) and never reach the scroll
        let dragUp = {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
                .press(forDuration: 0.05,
                       thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
        }
        dragUp()
        sleep(1)
        let collapsed = hero.frame.height
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "hero-collapsed"
        shot.lifetime = .keepAlways
        add(shot)
        XCTAssertLessThan(collapsed, full - 40, "hero should shrink with scroll")

        // keep scrolling: hero must pin at the floor, never vanish
        dragUp()
        sleep(1)
        let floored = hero.frame.height
        XCTAssertGreaterThanOrEqual(floored, 118, "hero must not collapse past the floor")
    }
}

final class SearchTests: XCTestCase {

    func testSearchFiltersAcrossFields() throws {
        let app = XCUIApplication(bundleIdentifier: "com.mickeyoh.naru")
        app.launchArguments = ["-naru-uitest-seed", "search-\(UUID().uuidString)"]
        app.launch()

        let button = app.buttons["search-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        button.tap()

        let field = app.textFields["Search your archive…"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        app.typeText("deep sea")
        sleep(1)

        // scope to tagged result tiles — the main grid behind the sheet
        // stays in the accessibility tree and would pollute global queries
        let results = app.buttons.matching(identifier: "search-result")
        XCTAssertTrue(results.matching(
            NSPredicate(format: "label CONTAINS 'deep sea'")).firstMatch.waitForExistence(timeout: 4),
            "matching tile should remain")
        XCTAssertFalse(results.matching(
            NSPredicate(format: "label CONTAINS 'Jeju'")).firstMatch.exists,
            "non-matching tile should be filtered out")

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "search-results"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
