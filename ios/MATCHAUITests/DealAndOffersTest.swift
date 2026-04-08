import XCTest

@MainActor
final class DealAndOffersTest: XCTestCase {

    func testChatDealAndOffers() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(8)

        // === 1. CHATS TAB ===
        app.tabBars.buttons["Chats"].tap()
        sleep(4)
        snap(app, "01-chats-list")

        // === 2. OPEN THE LAWN CHAT (has confirmed deal) ===
        for kw in ["The Lawn", "Lawn", "Motel", "COMO"] {
            let el = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", kw)).firstMatch
            if el.waitForExistence(timeout: 2) { el.tap(); sleep(3); break }
        }
        snap(app, "02-chat-opened")

        // === 3. CHECK PIPELINE VISIBILITY ===
        let pipelineLabels = ["Confirmed", "Draft", "Active Deal", "Check In", "Visited"]
        var pipelineFound = false
        for label in pipelineLabels {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch.waitForExistence(timeout: 2) {
                pipelineFound = true
                break
            }
        }
        snap(app, pipelineFound ? "03-pipeline-YES" : "03-pipeline-NO")

        // === 4. TAP DETAILS ON PIPELINE ===
        let detailsBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Details' OR label CONTAINS[c] 'detail'")).firstMatch
        if detailsBtn.waitForExistence(timeout: 2) {
            detailsBtn.tap()
            sleep(2)
            snap(app, "04-deal-details")
            // Close
            let closeBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Back' OR label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Done'")).firstMatch
            if closeBtn.exists { closeBtn.tap(); sleep(1) }
        }

        // === 5. CHECK-IN ===
        let checkInBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Check In' OR label CONTAINS[c] 'check in'")).firstMatch
        if checkInBtn.waitForExistence(timeout: 2) {
            snap(app, "05-checkin-button")
            checkInBtn.tap()
            sleep(3)
            snap(app, "06-after-checkin")
        }

        // Back
        let back = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Back' OR label CONTAINS[c] 'Messages'")).firstMatch
        if back.exists { back.tap(); sleep(1) }

        // === 6. OFFERS TAB ===
        app.tabBars.buttons["Offers"].tap()
        sleep(3)
        snap(app, "07-deals-tab")

        // Switch to Offers
        let offersBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Offers'")).firstMatch
        if offersBtn.waitForExistence(timeout: 2) {
            offersBtn.tap()
            sleep(3)
            snap(app, "08-offers-list")

            // Scroll
            app.swipeUp()
            sleep(1)
            snap(app, "09-offers-scrolled")

            // Tap an offer
            for kw in ["barter", "paid", "Reel", "stay", "Lawn", "COMO"] {
                let offer = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", kw)).firstMatch
                if offer.waitForExistence(timeout: 2) {
                    offer.tap()
                    sleep(2)
                    snap(app, "10-offer-detail")
                    break
                }
            }
        }

        // === 7. PROFILE TAB ===
        app.tabBars.buttons["Profile"].tap()
        sleep(2)
        snap(app, "11-profile")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
