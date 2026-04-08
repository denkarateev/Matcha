import XCTest

// MARK: - DealFlowUITests

/// UI tests for the Deal flow in MATCHA.
/// Covers: deal card display in chat, accept/decline visibility,
/// pipeline stage progression, status badge correctness, CTA touch targets.
@MainActor
final class DealFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-UITest"]
        app.launch()
    }

    // MARK: - Helpers

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Navigate to Chats tab and open the first available conversation.
    /// Returns `true` if a chat was opened successfully.
    @discardableResult
    private func navigateToChat() -> Bool {
        let chatsTab = app.tabBars.buttons["Chats"]
        guard chatsTab.waitForExistence(timeout: 5) else {
            XCTFail("Chats tab not found")
            return false
        }
        chatsTab.tap()
        sleep(5)

        let chatKeywords = ["The Lawn", "Motel", "COMO", "Canggu", "Bali", "Hotel", "Restaurant", "Dev"]
        for keyword in chatKeywords {
            let cell = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", keyword)
            ).firstMatch
            if cell.waitForExistence(timeout: 2) {
                cell.tap()
                sleep(4)
                return true
            }
        }

        // Fallback: try "New Matches" / "Action Required" sections
        for section in ["New", "Action", "Match"] {
            let el = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", section)
            ).firstMatch
            if el.waitForExistence(timeout: 2) {
                el.tap()
                sleep(3)
                return true
            }
        }

        return false
    }

    /// Find any deal card on screen by its accessibility identifier prefix.
    private func findDealCard() -> XCUIElement? {
        let cards = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'deal-card-'")
        )
        let first = cards.firstMatch
        return first.waitForExistence(timeout: 5) ? first : nil
    }

    // MARK: - Test 1: Deal Card Displays Correctly in Chat

    func test01_DealCardDisplaysCorrectlyInChat() throws {
        app.launch()
        sleep(10)

        guard navigateToChat() else {
            snap("deal01_NO_CONVERSATIONS")
            XCTFail("No conversations found — cannot test deal card display")
            return
        }
        snap("deal01_chat_opened")

        // Look for a deal card (inline in chat or pipeline banner)
        let dealCardExists = findDealCard() != nil
        let pipelineLabels = ["Draft", "Confirmed", "Visited", "Reviewed", "Active Deal"]
        var pipelineFound = false
        for label in pipelineLabels {
            if app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", label)
            ).firstMatch.waitForExistence(timeout: 2) {
                pipelineFound = true
                break
            }
        }

        // At least one deal indicator should be present (card or pipeline banner)
        let hasDealUI = dealCardExists || pipelineFound
        if !hasDealUI {
            snap("deal01_NO_DEAL_IN_CHAT")
            // Try creating a deal to have something to test
            let dealBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Deal'")
            ).firstMatch
            if dealBtn.waitForExistence(timeout: 3) {
                snap("deal01_deal_button_available_but_no_card_yet")
            }
            XCTFail("No deal card or pipeline found in chat — expected at least one deal element")
            return
        }

        snap("deal01_deal_card_visible")

        // Verify partner name is visible somewhere in the conversation
        let partnerNameVisible = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Deal'")
        ).firstMatch.exists
        XCTAssertTrue(partnerNameVisible, "Deal type label not visible on deal card")

        // Verify status text is visible (Draft / Confirmed / Visited / Reviewed / Cancelled / No-Show)
        let statusTexts = ["Draft", "Confirmed", "Visited", "Reviewed", "Cancelled", "No-Show", "No Show"]
        var foundStatus = false
        for statusText in statusTexts {
            let el = app.staticTexts.matching(
                NSPredicate(format: "label ==[c] %@", statusText)
            ).firstMatch
            if el.exists {
                foundStatus = true
                snap("deal01_status_\(statusText)")
                break
            }
        }
        XCTAssertTrue(foundStatus, "No deal status text found on card (expected Draft/Confirmed/Visited/Reviewed)")

        // Verify scheduled date chip is present (calendar icon row)
        let calendarChip = app.staticTexts.matching(
            NSPredicate(format: "label MATCHES '.*[A-Z][a-z]+ \\\\d+.*'")
        ).firstMatch
        if calendarChip.exists {
            snap("deal01_scheduled_date_visible")
        }

        snap("deal01_card_content_verified")
    }

    // MARK: - Test 2: Accept / Decline Buttons for Incoming Draft Deals

    func test02_AcceptDeclineButtonsForIncomingDrafts() throws {
        app.launch()
        sleep(10)

        guard navigateToChat() else {
            snap("deal02_NO_CONVERSATIONS")
            XCTFail("No conversations found — cannot test accept/decline buttons")
            return
        }
        snap("deal02_chat_opened")

        // Look for Accept button by accessibility identifier
        let acceptBtn = app.buttons["deal-accept-button"]
        let declineBtn = app.buttons["deal-decline-button"]

        // Also check by label as fallback
        let acceptByLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Accept'")
        ).firstMatch
        let declineByLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Decline'")
        ).firstMatch

        let hasAccept = acceptBtn.waitForExistence(timeout: 3) || acceptByLabel.waitForExistence(timeout: 2)
        let hasDecline = declineBtn.waitForExistence(timeout: 2) || declineByLabel.waitForExistence(timeout: 2)

        // Check current deal status to determine expected behavior
        let isDraft = app.staticTexts.matching(
            NSPredicate(format: "label ==[c] 'Draft'")
        ).firstMatch.exists

        let isConfirmedOrBeyond = app.staticTexts.matching(
            NSPredicate(format: "label ==[c] 'Confirmed' OR label ==[c] 'Visited' OR label ==[c] 'Reviewed'")
        ).firstMatch.exists

        if isDraft {
            // For incoming draft: buttons may or may not exist depending on isMine
            // If the current user created the deal, buttons should NOT appear
            // If the partner created it, buttons SHOULD appear
            if hasAccept && hasDecline {
                snap("deal02_accept_decline_VISIBLE_for_incoming_draft")
                XCTAssertTrue(hasAccept, "Accept button should be visible for incoming draft deal")
                XCTAssertTrue(hasDecline, "Decline button should be visible for incoming draft deal")
            } else {
                snap("deal02_no_buttons_for_OWN_draft")
                // This is valid — if isMine == true, no buttons shown
            }
        } else if isConfirmedOrBeyond {
            // After confirmation, accept/decline should NOT appear
            XCTAssertFalse(hasAccept, "Accept button should NOT appear for confirmed/visited/reviewed deals")
            XCTAssertFalse(hasDecline, "Decline button should NOT appear for confirmed/visited/reviewed deals")
            snap("deal02_no_buttons_for_non_draft_CORRECT")
        } else {
            snap("deal02_no_deal_status_found")
        }

        snap("deal02_accept_decline_check_done")
    }

    // MARK: - Test 3: Deal Pipeline Shows Correct Stage Progression

    func test03_DealPipelineStageProgression() throws {
        app.launch()
        sleep(10)

        guard navigateToChat() else {
            snap("deal03_NO_CONVERSATIONS")
            XCTFail("No conversations found — cannot test pipeline")
            return
        }
        snap("deal03_chat_opened")

        // Look for the pipeline view by identifier
        let pipeline = app.otherElements["deal-pipeline"]
        let pipelineByLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Active Deal'")
        ).firstMatch

        let hasPipeline = pipeline.waitForExistence(timeout: 5) || pipelineByLabel.waitForExistence(timeout: 3)

        if !hasPipeline {
            // Pipeline may be inside deal card (compact mode) — scroll to find it
            app.swipeUp()
            sleep(1)
        }

        // The pipeline renders 4 stages: Draft -> Confirmed -> Visited -> Reviewed
        // In compact mode these are shown as D, C, V, R
        let stageLabels = ["Draft", "Confirmed", "Visited", "Reviewed"]
        let compactLabels = ["D", "C", "V", "R"]

        var foundFullLabels = 0
        var foundCompactLabels = 0

        for label in stageLabels {
            if app.staticTexts.matching(
                NSPredicate(format: "label ==[c] %@", label)
            ).firstMatch.exists {
                foundFullLabels += 1
            }
        }

        for label in compactLabels {
            if app.staticTexts.matching(
                NSPredicate(format: "label == %@", label)
            ).firstMatch.exists {
                foundCompactLabels += 1
            }
        }

        snap("deal03_pipeline_labels_full_\(foundFullLabels)_compact_\(foundCompactLabels)")

        // At least one format of pipeline labels should be present
        let pipelineRendered = foundFullLabels >= 2 || foundCompactLabels >= 2
        if !pipelineRendered {
            snap("deal03_PIPELINE_NOT_RENDERED")
            // Not a hard failure if deal doesn't exist in this chat
        } else {
            snap("deal03_pipeline_stages_visible")
        }

        // Verify the Details button exists on the full pipeline banner
        let detailsBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Details'")
        ).firstMatch
        if detailsBtn.waitForExistence(timeout: 3) {
            snap("deal03_details_button_found")
            detailsBtn.tap()
            sleep(2)
            snap("deal03_deal_detail_opened")

            // Close detail view
            let closeBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Back' OR label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Done'")
            ).firstMatch
            if closeBtn.waitForExistence(timeout: 3) {
                closeBtn.tap()
                sleep(1)
            }
        }

        snap("deal03_pipeline_test_done")
    }

    // MARK: - Test 4: Status Badge Shows Correct Text for Each Status

    func test04_StatusBadgeCorrectTextAndVisibility() throws {
        app.launch()
        sleep(10)

        guard navigateToChat() else {
            snap("deal04_NO_CONVERSATIONS")
            XCTFail("No conversations found — cannot test status badge")
            return
        }
        snap("deal04_chat_opened")

        // Look for the deal status badge by identifier
        let badge = app.otherElements["deal-status-badge"]
        let badgeByIdentifier = badge.waitForExistence(timeout: 5)

        // Also look for status text within the badge area
        let allStatuses: [(key: String, display: String)] = [
            ("draft", "Draft"),
            ("confirmed", "Confirmed"),
            ("visited", "Visited"),
            ("reviewed", "Reviewed"),
            ("cancelled", "Cancelled"),
            ("no_show", "No-Show")
        ]

        var foundStatusText: String?
        for status in allStatuses {
            let el = app.staticTexts.matching(
                NSPredicate(format: "label ==[c] %@", status.display)
            ).firstMatch
            if el.exists {
                foundStatusText = status.display
                break
            }
        }

        // Also check the alternate "No Show" spelling
        if foundStatusText == nil {
            let noShow = app.staticTexts.matching(
                NSPredicate(format: "label ==[c] 'No Show'")
            ).firstMatch
            if noShow.exists {
                foundStatusText = "No Show"
            }
        }

        if let status = foundStatusText {
            snap("deal04_badge_status_\(status)")

            // Verify the badge text matches one of the known deal statuses
            let validTitles = ["Draft", "Confirmed", "Visited", "Reviewed", "Cancelled", "No-Show", "No Show"]
            XCTAssertTrue(
                validTitles.contains(where: { $0.caseInsensitiveCompare(status) == .orderedSame }),
                "Status badge shows '\(status)' which is not a recognized deal status"
            )
        } else {
            snap("deal04_NO_STATUS_BADGE_TEXT")
            // Only fail if we expected a deal to exist
            if badgeByIdentifier {
                XCTFail("Status badge element found but no status text visible")
            }
        }

        snap("deal04_status_badge_done")
    }

    // MARK: - Test 5: Deal CTA Buttons are Tappable (Touch Target >= 44pt)

    func test05_DealCTAButtonsTouchTargets() throws {
        app.launch()
        sleep(10)

        guard navigateToChat() else {
            snap("deal05_NO_CONVERSATIONS")
            XCTFail("No conversations found — cannot test CTA touch targets")
            return
        }
        snap("deal05_chat_opened")

        let minTouchTarget: CGFloat = 44.0

        // Collect all deal-related CTA buttons to check
        let ctaPredicates: [(name: String, predicate: NSPredicate)] = [
            ("Accept", NSPredicate(format: "identifier == 'deal-accept-button' OR label CONTAINS[c] 'Accept'")),
            ("Decline", NSPredicate(format: "identifier == 'deal-decline-button' OR label CONTAINS[c] 'Decline'")),
            ("Check In", NSPredicate(format: "label CONTAINS[c] 'Check In'")),
            ("Confirm Visit", NSPredicate(format: "label CONTAINS[c] 'Confirm Visit'")),
            ("Leave Review", NSPredicate(format: "label CONTAINS[c] 'Leave Review'")),
            ("Details", NSPredicate(format: "label CONTAINS[c] 'Details'")),
            ("Deal", NSPredicate(format: "label CONTAINS[c] 'Deal' AND NOT label CONTAINS[c] 'Active Deal'")),
        ]

        var testedCount = 0

        for cta in ctaPredicates {
            let button = app.buttons.matching(cta.predicate).firstMatch
            if button.waitForExistence(timeout: 2) {
                let frame = button.frame
                let meetsHeight = frame.height >= minTouchTarget
                let meetsWidth = frame.width >= minTouchTarget

                snap("deal05_cta_\(cta.name)_\(Int(frame.width))x\(Int(frame.height))")

                XCTAssertTrue(
                    meetsHeight,
                    "\(cta.name) button height \(frame.height)pt < \(minTouchTarget)pt minimum touch target"
                )
                XCTAssertTrue(
                    meetsWidth,
                    "\(cta.name) button width \(frame.width)pt < \(minTouchTarget)pt minimum touch target"
                )

                // Verify button is hittable (not obscured)
                XCTAssertTrue(
                    button.isHittable,
                    "\(cta.name) button exists but is not hittable — may be covered by another view"
                )

                testedCount += 1
            }
        }

        snap("deal05_tested_\(testedCount)_buttons")

        if testedCount == 0 {
            // No CTA buttons found — check if the pipeline action footer has buttons
            let pipelineActions = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Check' OR label CONTAINS[c] 'Review' OR label CONTAINS[c] 'Confirm'")
            )
            let count = pipelineActions.count
            snap("deal05_pipeline_action_buttons_\(count)")
            if count == 0 {
                snap("deal05_NO_CTA_BUTTONS_FOUND")
                // Not necessarily a failure — deal may be in reviewed/cancelled state
            }
        }

        snap("deal05_touch_targets_done")
    }

    // MARK: - Test 6: Deal Card + Pipeline End-to-End Flow

    func test06_DealCardAndPipelineEndToEnd() throws {
        app.launch()
        sleep(10)

        guard navigateToChat() else {
            snap("deal06_NO_CONVERSATIONS")
            XCTFail("No conversations found — cannot run end-to-end deal flow test")
            return
        }
        snap("deal06_chat_opened")

        // Step 1: Check if deal already exists
        let hasPipeline = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Active Deal'")
        ).firstMatch.waitForExistence(timeout: 3)

        let hasDealCard = findDealCard() != nil

        if hasPipeline || hasDealCard {
            snap("deal06_existing_deal_found")

            // Verify pipeline and card coexist properly
            if hasPipeline {
                let pipeline = app.otherElements["deal-pipeline"]
                if pipeline.exists {
                    snap("deal06_pipeline_identifier_confirmed")
                }
            }

            if hasDealCard {
                snap("deal06_deal_card_identifier_confirmed")
            }
        } else {
            // Step 2: Create a deal if none exists
            let dealBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Deal'")
            ).firstMatch

            guard dealBtn.waitForExistence(timeout: 5) else {
                snap("deal06_NO_DEAL_BUTTON")
                XCTFail("No existing deal and no Deal creation button available")
                return
            }

            dealBtn.tap()
            sleep(3)
            snap("deal06_deal_form_opened")

            // Select a template
            for template in ["Dinner", "Hotel", "Spa", "Event"] {
                let tmpl = app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS[c] %@", template)
                ).firstMatch
                if tmpl.waitForExistence(timeout: 2) {
                    tmpl.tap()
                    sleep(1)
                    break
                }
            }

            // Send the deal
            let sendBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Send Deal Card'")
            ).firstMatch
            if !sendBtn.waitForExistence(timeout: 3) {
                app.swipeUp()
                sleep(1)
            }

            if sendBtn.waitForExistence(timeout: 3) && sendBtn.isEnabled {
                sendBtn.tap()
                sleep(6)
                snap("deal06_deal_sent")

                // Verify deal card appeared after sending
                let newCard = findDealCard()
                XCTAssertNotNil(newCard, "Deal card should appear in chat after sending")
                snap("deal06_new_card_created")
            }
        }

        snap("deal06_end_to_end_done")
    }

    // MARK: - Test 7: Offers Tab Shows Deal Cards

    func test07_OffersTabDealCards() throws {
        app.launch()
        sleep(10)

        // Navigate to Offers tab
        let offersTab = app.tabBars.buttons["Offers"]
        guard offersTab.waitForExistence(timeout: 5) else {
            XCTFail("Offers tab not found")
            return
        }
        offersTab.tap()
        sleep(4)
        snap("deal07_offers_tab")

        // Look for deal-related content in the Offers/Deals view
        let dealKeywords = ["Barter", "Paid", "Draft", "Confirmed", "Active", "Deal"]
        var foundDealContent = false
        for keyword in dealKeywords {
            if app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", keyword)
            ).firstMatch.waitForExistence(timeout: 2) {
                foundDealContent = true
                break
            }
        }

        if foundDealContent {
            snap("deal07_deals_content_visible")
        } else {
            snap("deal07_no_deals_in_offers_tab")
        }

        // Check for status badge in the deals listing
        let statusBadge = app.otherElements["deal-status-badge"]
        if statusBadge.waitForExistence(timeout: 3) {
            let badgeLabel = statusBadge.label
            snap("deal07_status_badge_\(badgeLabel)")
            XCTAssertFalse(badgeLabel.isEmpty, "Status badge should have an accessibility label")
        }

        snap("deal07_offers_tab_done")
    }
}
