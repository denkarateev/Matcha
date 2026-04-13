import XCTest

// MARK: - ChatsUITests
/// UI tests for the redesigned ChatsView + ChatConversationView.
/// Covers: segments, pipeline in list, swipe actions, conversation view, input bar, deal banner.

final class ChatsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)"]
    }

    private func launchAndLogin() {
        // Pre-login via API — store token directly
        preLoginViaAPI()
        app.launch()
        sleep(12)
        // If tabs don't appear, try UI login flow
        if !app.tabBars.firstMatch.waitForExistence(timeout: 8) {
            ensureLoggedIn()
        }
    }

    /// Login via backend API and inject credentials as launch env
    private func preLoginViaAPI() {
        let url = URL(string: "http://188.253.19.166:8842/api/v1/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email": "dev@matcha.app",
            "password": "Password123!"
        ])
        let sem = DispatchSemaphore(value: 0)
        var token: String?
        var userId: String?
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                token = json["access_token"] as? String
                if let user = json["user"] as? [String: Any] {
                    userId = user["id"] as? String
                }
            }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 10)

        if let token = token, let userId = userId {
            app.launchEnvironment["MATCHA_TEST_TOKEN"] = token
            app.launchEnvironment["MATCHA_TEST_USER_ID"] = userId
            app.launchEnvironment["MATCHA_TEST_ROLE"] = "blogger"
        }
    }

    /// If onboarding is showing, log in as dev@matcha.app
    private func ensureLoggedIn() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 8) { return } // Already logged in

        // Step 1: Skip slides — tap "Next" / "Get Started" until we leave slides
        for _ in 0..<5 {
            let nextBtn = app.buttons.matching(NSPredicate(format: "label == 'Next' OR label == 'Get Started'")).firstMatch
            if nextBtn.waitForExistence(timeout: 3) {
                nextBtn.tap()
                sleep(2)
            } else {
                break
            }
            if tabBar.exists { return }
        }

        // Step 2: On welcome screen — tap "I already have an account"
        let alreadyBtn = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'already have'")).firstMatch
        if alreadyBtn.waitForExistence(timeout: 5) {
            alreadyBtn.tap()
            sleep(2)
        }

        // Step 3: Switch to Login mode
        let logInMode = app.staticTexts.matching(NSPredicate(format: "label == 'Log In'")).firstMatch
        if logInMode.waitForExistence(timeout: 3) {
            logInMode.tap()
            sleep(1)
        }

        // Step 4: Enter email
        let emailField = app.textFields.firstMatch
        if emailField.waitForExistence(timeout: 5) {
            emailField.tap()
            sleep(1)
            emailField.typeText("dev@matcha.app")
        }

        // Step 5: Enter password
        let passwordField = app.secureTextFields.firstMatch
        if passwordField.waitForExistence(timeout: 3) {
            passwordField.tap()
            sleep(1)
            passwordField.typeText("Password123!")
        }

        // Step 6: Submit
        sleep(1)
        let submitBtn = app.buttons.matching(NSPredicate(format: "label == 'Log In'")).firstMatch
        if !submitBtn.waitForExistence(timeout: 3) {
            app.swipeUp()
            sleep(1)
        }
        if submitBtn.waitForExistence(timeout: 5) {
            snap("login_before_submit")
            submitBtn.tap()
            sleep(15)
            snap("login_after_submit")
        } else {
            snap("login_no_submit_btn")
        }

        // After login, app might show mini profile step — skip if Get Started
        let getStartedAfter = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Get Started' OR label CONTAINS[c] 'Continue' OR label CONTAINS[c] 'Skip'")).firstMatch
        if getStartedAfter.waitForExistence(timeout: 5) {
            getStartedAfter.tap()
            sleep(5)
            snap("login_skipped_post_step")
        }

        // Wait for tabs
        if !tabBar.waitForExistence(timeout: 20) {
            snap("login_FAILED_no_tabs")
        }
    }

    // MARK: - Test 1: ChatsView Title & Segments

    func test01_ChatsViewTitleAndSegments() throws {
        launchAndLogin()
        let chatsTab = app.tabBars.buttons["Chats"]
        XCTAssertTrue(chatsTab.waitForExistence(timeout: 5), "Chats tab not found")
        chatsTab.tap()
        sleep(4)
        snap("chats_01_initial")

        // Title "Messages" must exist
        let title = app.staticTexts.matching(NSPredicate(format: "label == 'Messages'")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 3), "Title 'Messages' not found")

        // Segment buttons
        let allBtn = app.buttons.matching(NSPredicate(format: "label == 'All'")).firstMatch
        let messagesBtn = app.buttons.matching(NSPredicate(format: "label == 'Messages'")).firstMatch
        let dealsBtn = app.buttons.matching(NSPredicate(format: "label == 'Deals'")).firstMatch

        XCTAssertTrue(allBtn.waitForExistence(timeout: 3), "All segment not found")
        XCTAssertTrue(messagesBtn.exists, "Messages segment not found")
        XCTAssertTrue(dealsBtn.exists, "Deals segment not found")

        // Tap Messages segment
        messagesBtn.tap()
        sleep(2)
        snap("chats_01_messages_segment")

        // Tap Deals segment
        dealsBtn.tap()
        sleep(2)
        snap("chats_01_deals_segment")

        // Check Deals section headers
        let activeDeals = app.staticTexts.matching(NSPredicate(format: "label == 'Active Deals'")).firstMatch
        let completed = app.staticTexts.matching(NSPredicate(format: "label == 'Completed'")).firstMatch
        if activeDeals.exists || completed.exists {
            snap("chats_01_deals_sections_visible")
        }

        // Back to All
        allBtn.tap()
        sleep(2)
        snap("chats_01_all_segment")
    }

    // MARK: - Test 2: New Matches Section

    func test02_NewMatchesSection() throws {
        launchAndLogin()
        app.tabBars.buttons["Chats"].tap()
        sleep(4)

        // Header
        let newMatches = app.staticTexts.matching(NSPredicate(format: "label == 'New Matches'")).firstMatch
        XCTAssertTrue(newMatches.waitForExistence(timeout: 3), "'New Matches' header not found")

        let subtitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Waiting for their first message'")).firstMatch
        XCTAssertTrue(subtitle.exists, "Subtitle 'Waiting for their first message' not found")

        // Likes card
        let likesLabel = app.staticTexts.matching(NSPredicate(format: "label == 'Likes'")).firstMatch
        XCTAssertTrue(likesLabel.waitForExistence(timeout: 3), "Likes card not found")

        snap("chats_02_new_matches")
    }

    // MARK: - Test 3: Deal Pipeline in Chat List Row

    func test03_DealPipelineInListRow() throws {
        launchAndLogin()
        app.tabBars.buttons["Chats"].tap()
        sleep(4)

        // Look for pipeline labels in conversation rows
        let draftLabel = app.staticTexts.matching(NSPredicate(format: "label == 'Draft'")).firstMatch
        let confirmedLabel = app.staticTexts.matching(NSPredicate(format: "label == 'Confirmed'")).firstMatch
        let visitedLabel = app.staticTexts.matching(NSPredicate(format: "label == 'Visited'")).firstMatch
        let reviewedLabel = app.staticTexts.matching(NSPredicate(format: "label == 'Reviewed'")).firstMatch

        let hasPipeline = draftLabel.waitForExistence(timeout: 5) ||
                          confirmedLabel.waitForExistence(timeout: 2)

        if hasPipeline {
            snap("chats_03_pipeline_visible")
            // "Your move" CTA
            let yourMove = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Your move'")).firstMatch
            if yourMove.exists {
                snap("chats_03_your_move_cta")
            }
        } else {
            snap("chats_03_no_pipeline_no_deals")
        }
    }

    // MARK: - Test 4: Swipe Actions on Chat Row

    func test04_SwipeActions() throws {
        launchAndLogin()
        app.tabBars.buttons["Chats"].tap()
        sleep(4)

        // Find first conversation cell
        let firstChat = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] 'The Lawn' OR label CONTAINS[c] 'Motel' OR label CONTAINS[c] 'COMO' OR label CONTAINS[c] 'Open conversation'"
        )).firstMatch

        guard firstChat.waitForExistence(timeout: 5) else {
            snap("chats_04_no_chats_for_swipe")
            return
        }

        // Swipe left — should reveal Delete
        firstChat.swipeLeft()
        sleep(1)
        snap("chats_04_swipe_left")

        let deleteBtn = app.buttons.matching(NSPredicate(format: "label == 'Delete'")).firstMatch
        XCTAssertTrue(deleteBtn.waitForExistence(timeout: 3), "Delete button not shown on swipe left")

        // Dismiss swipe
        firstChat.swipeRight()
        sleep(1)

        // Swipe right — should reveal Mute
        firstChat.swipeRight()
        sleep(1)
        snap("chats_04_swipe_right")

        let muteBtn = app.buttons.matching(NSPredicate(format: "label == 'Mute' OR label == 'Unmute'")).firstMatch
        XCTAssertTrue(muteBtn.waitForExistence(timeout: 3), "Mute button not shown on swipe right")

        snap("chats_04_swipe_actions_verified")
    }

    // MARK: - Test 5: Open Conversation & Verify Layout

    func test05_ConversationLayout() throws {
        launchAndLogin()
        app.tabBars.buttons["Chats"].tap()
        sleep(4)

        // Open first chat
        let chatNames = ["The Lawn", "Motel", "COMO"]
        var opened = false
        for name in chatNames {
            let cell = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
            if cell.waitForExistence(timeout: 3) {
                cell.tap()
                sleep(4)
                opened = true
                snap("chats_05_conversation_opened")
                break
            }
        }

        guard opened else {
            snap("chats_05_no_conversation")
            return
        }

        // Back button (chevron)
        let backBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Back'")).firstMatch
        let chevronBtn = app.images.matching(NSPredicate(format: "label CONTAINS[c] 'chevron'")).firstMatch
        XCTAssertTrue(backBtn.exists || chevronBtn.exists, "Back button not found in conversation toolbar")

        // Partner name in toolbar
        for name in chatNames {
            let partnerName = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
            if partnerName.exists {
                snap("chats_05_partner_name_visible")
                break
            }
        }

        // Input bar elements
        let plusBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'plus' OR label CONTAINS[c] '+'")).firstMatch
        let messageField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'Message'")).firstMatch

        if messageField.waitForExistence(timeout: 3) {
            snap("chats_05_input_bar_visible")
        }

        // Deal pipeline banner
        let activeDeal = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Active Deal' OR label CONTAINS[c] 'ACTIVE DEAL'")).firstMatch
        if activeDeal.exists {
            snap("chats_05_deal_banner_visible")

            // Details button
            let detailsBtn = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Details'")).firstMatch
            XCTAssertTrue(detailsBtn.exists, "Details > button not found in deal banner")
        }

        // Quick replies
        let quickReply = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'See you' OR label CONTAINS[c] 'Looking forward' OR label CONTAINS[c] 'Quick question'")).firstMatch
        if quickReply.waitForExistence(timeout: 3) {
            snap("chats_05_quick_replies_visible")
        }

        snap("chats_05_conversation_layout_done")
    }

    // MARK: - Test 6: Message Bubbles Exist

    func test06_MessageBubbles() throws {
        launchAndLogin()
        app.tabBars.buttons["Chats"].tap()
        sleep(4)

        // Open a conversation that has messages
        let chatNames = ["The Lawn", "Motel", "COMO"]
        var opened = false
        for name in chatNames {
            let cell = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
            if cell.waitForExistence(timeout: 3) {
                cell.tap()
                sleep(4)
                opened = true
                break
            }
        }

        guard opened else { return }

        // Check for any text content in messages
        let messageTexts = ["Hey", "Welcome", "Great", "deal", "collab", "content", "Looking forward", "Amazing", "check in"]
        var foundMessages = 0
        for text in messageTexts {
            let msg = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
            if msg.exists { foundMessages += 1 }
        }

        XCTAssertGreaterThan(foundMessages, 0, "No message bubbles found in conversation")
        snap("chats_06_messages_found_\(foundMessages)")

        // System messages (deal confirmed, check-in, etc.)
        let systemMsg = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Deal confirmed' OR label CONTAINS[c] 'checked in' OR label CONTAINS[c] 'confirmed'")).firstMatch
        if systemMsg.exists {
            snap("chats_06_system_message_found")
        }
    }

    // MARK: - Test 7: Empty States

    func test07_EmptyStates() throws {
        launchAndLogin()
        app.tabBars.buttons["Chats"].tap()
        sleep(4)

        // Switch to Messages segment and check empty state
        let messagesBtn = app.buttons.matching(NSPredicate(format: "label == 'Messages'")).firstMatch
        if messagesBtn.waitForExistence(timeout: 3) {
            messagesBtn.tap()
            sleep(2)

            let emptyMessages = app.staticTexts.matching(NSPredicate(format: "label == 'No messages yet'")).firstMatch
            if emptyMessages.exists {
                snap("chats_07_empty_messages")
                // Verify correct subtitle
                let subtitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'without deals'")).firstMatch
                XCTAssertTrue(subtitle.exists, "Empty messages subtitle wrong")
            }
        }

        // Switch to Deals segment and check empty state
        let dealsBtn = app.buttons.matching(NSPredicate(format: "label == 'Deals'")).firstMatch
        if dealsBtn.waitForExistence(timeout: 3) {
            dealsBtn.tap()
            sleep(2)

            let emptyDeals = app.staticTexts.matching(NSPredicate(format: "label == 'No deals yet'")).firstMatch
            if emptyDeals.exists {
                snap("chats_07_empty_deals")
                let subtitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Start a deal'")).firstMatch
                XCTAssertTrue(subtitle.exists, "Empty deals subtitle wrong")
            }
        }

        snap("chats_07_empty_states_done")
    }

    // MARK: - Helpers

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
