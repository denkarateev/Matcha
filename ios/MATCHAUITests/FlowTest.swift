import XCTest

// MARK: - FlowTest

/// Comprehensive XCUITest suite for MATCHA app critical flows.
/// Covers: Match Feed, Chat + Deal, Business Login, Onboarding Cleanliness, All Tabs.
@MainActor
final class FlowTest: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)"]
    }

    // MARK: - Test 1: Blogger Match Feed

    func test01_BloggerMatchFeed() throws {
        app.launch()
        sleep(10) // Wait for bootstrap + auto-login as dev@matcha.app (blogger)
        snap("01_feed_initial")

        // Navigate to Match tab
        let matchTab = app.tabBars.buttons["Match"]
        if matchTab.waitForExistence(timeout: 5) {
            matchTab.tap()
            sleep(5)
        }
        snap("01_feed_match_tab")

        // Verify feed has loaded — look for action buttons (skip/like)
        let skipBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skip this profile'")).firstMatch
        let likeBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Like this profile'")).firstMatch

        let feedLoaded = skipBtn.waitForExistence(timeout: 10) || likeBtn.waitForExistence(timeout: 3)

        if !feedLoaded {
            snap("01_feed_EMPTY_OR_LOADING")
            XCTFail("Match feed did not load any profiles — expected cards with skip/like buttons")
        }

        snap("01_feed_card_content")

        XCTAssertTrue(skipBtn.exists, "Skip button not found on match feed card")
        XCTAssertTrue(likeBtn.exists, "Like button not found on match feed card")

        // Check card content (followers, looking for, collabs, etc.)
        let hasFollowers = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'followers'")).firstMatch.exists
        let hasLookingFor = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Looking for'")).firstMatch.exists
        snap("01_feed_card_details_followers_\(hasFollowers)_lookingFor_\(hasLookingFor)")

        // Swipe left — tap Skip button
        if skipBtn.exists {
            skipBtn.tap()
            sleep(2)
            snap("01_feed_after_skip")
        }

        // Swipe right — tap Like button (creates potential match)
        if likeBtn.waitForExistence(timeout: 5) {
            likeBtn.tap()
            sleep(3)
            snap("01_feed_after_like")
        }

        // Check for match celebration overlay
        let matchCelebration = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'match'")).firstMatch
        if matchCelebration.waitForExistence(timeout: 3) {
            snap("01_feed_match_celebration")
            let dismissBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Send' OR label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Keep'")).firstMatch
            if dismissBtn.waitForExistence(timeout: 3) {
                dismissBtn.tap()
                sleep(1)
            }
        }

        // Like a few more to maximize chance of matches for test02
        for i in 0..<3 {
            if likeBtn.waitForExistence(timeout: 3) {
                likeBtn.tap()
                sleep(2)
                // Dismiss match overlay if it appears
                let overlay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'match'")).firstMatch
                if overlay.waitForExistence(timeout: 2) {
                    let dismiss = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Send' OR label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Keep'")).firstMatch
                    if dismiss.waitForExistence(timeout: 2) { dismiss.tap(); sleep(1) }
                }
            }
        }

        snap("01_feed_final")
    }

    // MARK: - Test 2: Chat + Deal Creation

    func test02_ChatAndDealCreation() throws {
        app.launch()
        sleep(10)

        // Go to Chats tab
        let chatsTab = app.tabBars.buttons["Chats"]
        XCTAssertTrue(chatsTab.waitForExistence(timeout: 5), "Chats tab not found")
        chatsTab.tap()
        sleep(5)
        snap("02_chats_tab")

        // Look for conversations — try common partner names and generic patterns
        let chatKeywords = ["The Lawn", "Motel", "COMO", "Canggu", "Bali", "Hotel", "Restaurant", "Dev", "User"]
        var foundChat = false

        for keyword in chatKeywords {
            let chatCell = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", keyword)).firstMatch
            if chatCell.waitForExistence(timeout: 2) {
                chatCell.tap()
                sleep(4)
                foundChat = true
                snap("02_chat_opened")
                break
            }
        }

        // Try "New Matches" or "Action Required" sections
        if !foundChat {
            let sections = ["New", "Action", "Match"]
            for section in sections {
                let el = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", section)).firstMatch
                if el.waitForExistence(timeout: 2) {
                    el.tap()
                    sleep(3)
                    foundChat = true
                    snap("02_chat_opened_section")
                    break
                }
            }
        }

        if !foundChat {
            snap("02_NO_CONVERSATIONS_fresh_backend")
            // On a fresh backend, there may be no chats yet — this is expected behavior
            // Record as a known condition, not necessarily a bug
            XCTFail("No conversations found in Chats tab (expected on fresh backend without prior matches)")
            return
        }

        // Check if there's a first-message prompt or waiting state
        let yourMove = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Your move'")).firstMatch
        let bloggerFirst = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Blogger writes first'")).firstMatch

        if yourMove.waitForExistence(timeout: 3) {
            snap("02_your_move_prompt")
            // Blogger needs to send a message first — type a message
            let inputField = app.textFields.firstMatch
            if inputField.waitForExistence(timeout: 3) {
                inputField.tap()
                sleep(1)
                inputField.typeText("Hey! Want to collaborate?")
                sleep(1)
                // Send message
                let sendMsgBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Send'")).firstMatch
                if sendMsgBtn.waitForExistence(timeout: 3) {
                    sendMsgBtn.tap()
                    sleep(3)
                }
            }
        } else if bloggerFirst.waitForExistence(timeout: 2) {
            snap("02_waiting_for_blogger")
            // Business side — can't write first. Skip deal creation.
            return
        }

        // Look for Deal button in toolbar
        let dealBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Deal'")).firstMatch
        guard dealBtn.waitForExistence(timeout: 5) else {
            snap("02_NO_DEAL_BUTTON")
            // Check if deal pipeline already exists
            let pipeline = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Draft' OR label CONTAINS[c] 'Accepted' OR label CONTAINS[c] 'Active'")).firstMatch
            if pipeline.exists {
                snap("02_deal_pipeline_already_exists")
                return
            }
            XCTFail("Deal button not found in chat toolbar")
            return
        }

        // Check if deal button is actually tappable (not disabled)
        snap("02_deal_button_found")
        dealBtn.tap()
        sleep(3)
        snap("02_after_deal_tap")

        // Verify deal form opened — look for form elements
        let navBarTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'New Deal Card'")).firstMatch
        let dealWithText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Deal with'")).firstMatch
        let cancelBtn = app.buttons.matching(NSPredicate(format: "label == 'Cancel'")).firstMatch
        let quickMode = app.staticTexts.matching(NSPredicate(format: "label == 'Quick'")).firstMatch

        let formOpened = navBarTitle.waitForExistence(timeout: 5) ||
                         dealWithText.waitForExistence(timeout: 2) ||
                         cancelBtn.waitForExistence(timeout: 2) ||
                         quickMode.waitForExistence(timeout: 2)

        if !formOpened {
            snap("02_deal_form_NOT_opened")
            // The button might have been disabled — deal creation not allowed
            // This can happen if canStartDeal is false
            XCTFail("Deal form did not open — button may be disabled (canStartDeal=false)")
            return
        }

        snap("02_deal_form_opened")

        // Select a quick template
        let templates = ["Dinner", "Hotel", "Spa", "Event"]
        for template in templates {
            let tmplBtn = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", template)).firstMatch
            if tmplBtn.waitForExistence(timeout: 2) {
                tmplBtn.tap()
                sleep(1)
                snap("02_template_selected")
                break
            }
        }

        // Scroll down to find the Send button if needed
        let sendBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Send Deal Card'")).firstMatch
        if !sendBtn.waitForExistence(timeout: 3) {
            app.swipeUp()
            sleep(1)
        }

        guard sendBtn.waitForExistence(timeout: 5) else {
            snap("02_NO_SEND_BUTTON")
            XCTFail("'Send Deal Card' button not found in deal form")
            return
        }

        if sendBtn.isEnabled {
            sendBtn.tap()
            sleep(6)
            snap("02_deal_sent")

            // Check for error message
            let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'already have' OR label CONTAINS[c] 'expired' OR label CONTAINS[c] 'not found'")).firstMatch
            if errorText.waitForExistence(timeout: 3) {
                snap("02_deal_send_ERROR_message")
            }
        } else {
            snap("02_send_button_DISABLED")
        }

        snap("02_after_deal_flow")
    }

    // MARK: - Test 3: Business Login

    func test03_BusinessLogin() throws {
        // Pre-register business account on backend (idempotent — 409 if already exists)
        registerAccountOnBackend(
            email: "hello@thelawncanggu.com",
            password: "Password123!",
            role: "business",
            fullName: "The Lawn Canggu"
        )

        app.launch()
        sleep(10)

        // Step 1: Sign out from current blogger account
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab not found")
        profileTab.tap()
        sleep(3)
        snap("03_profile_tab")

        // Scroll down to find Sign Out
        let signOutBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Sign Out'")).firstMatch
        for _ in 0..<5 {
            if signOutBtn.exists { break }
            app.swipeUp()
            sleep(1)
        }

        guard signOutBtn.waitForExistence(timeout: 5) else {
            snap("03_NO_SIGN_OUT_BUTTON")
            XCTFail("Sign Out button not found on Profile tab")
            return
        }
        signOutBtn.tap()
        sleep(5)
        snap("03_after_sign_out")

        // Verify welcome screen
        let getStartedBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Get started'")).firstMatch
        XCTAssertTrue(getStartedBtn.waitForExistence(timeout: 8), "Welcome screen not shown after sign out")
        snap("03_welcome_screen")

        // Tap "I already have an account"
        let loginBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Log in to existing account'")).firstMatch
        guard loginBtn.waitForExistence(timeout: 5) else {
            snap("03_NO_LOGIN_BUTTON")
            XCTFail("'I already have an account' button not found")
            return
        }
        loginBtn.tap()
        sleep(3)
        snap("03_registration_screen")

        // We should now be on the Registration screen which has a mode picker.
        // The "I already have an account" button should automatically switch to Login mode.
        // But verify we're in login mode by checking for "Welcome back" text
        let welcomeBack = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Welcome back'")).firstMatch
        if !welcomeBack.waitForExistence(timeout: 3) {
            // Switch to Login mode manually
            let logInModeBtn = app.staticTexts.matching(NSPredicate(format: "label == 'Log In'")).firstMatch
            if logInModeBtn.waitForExistence(timeout: 3) {
                logInModeBtn.tap()
                sleep(1)
            }
        }
        snap("03_login_mode_selected")

        // Enter email
        let emailField = app.textFields.firstMatch
        guard emailField.waitForExistence(timeout: 5) else {
            snap("03_NO_EMAIL_FIELD")
            XCTFail("Email field not found")
            return
        }
        emailField.tap()
        sleep(1)
        emailField.typeText("hello@thelawncanggu.com")
        sleep(1)

        // Enter password
        let passwordField = app.secureTextFields.firstMatch
        guard passwordField.waitForExistence(timeout: 5) else {
            snap("03_NO_PASSWORD_FIELD")
            XCTFail("Password field not found")
            return
        }
        passwordField.tap()
        sleep(1)
        passwordField.typeText("Password123!")
        sleep(1)
        snap("03_credentials_entered")

        // Tap somewhere neutral to dismiss keyboard, then scroll to find login button
        let headerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'MATCHA Access'")).firstMatch
        if headerText.exists {
            headerText.tap()
            sleep(1)
        }

        // Tap the "Log in to MATCHA" submit button
        let submitBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Log in to MATCHA'")).firstMatch
        if !submitBtn.waitForExistence(timeout: 3) {
            // Scroll to find it
            app.swipeUp()
            sleep(1)
        }
        guard submitBtn.waitForExistence(timeout: 5) else {
            snap("03_NO_SUBMIT_BUTTON")
            XCTFail("Login submit button ('Log in to MATCHA') not found")
            return
        }
        snap("03_before_submit")
        submitBtn.tap()
        sleep(12)
        snap("03_after_business_login")

        // Check for error messages on the login screen
        let errorBanner = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Invalid' OR label CONTAINS[c] 'error' OR label CONTAINS[c] 'wrong'")).firstMatch
        if errorBanner.waitForExistence(timeout: 3) {
            snap("03_LOGIN_ERROR")
            XCTFail("Business login failed with error: \(errorBanner.label)")
            return
        }

        // Verify we land on tabs
        let tabBarExists = app.tabBars.firstMatch.waitForExistence(timeout: 15)
        XCTAssertTrue(tabBarExists, "Tab bar not shown after business login — might still be on onboarding")

        if tabBarExists {
            // Verify business sees the Match feed (should show blogger profiles)
            let matchTab = app.tabBars.buttons["Match"]
            if matchTab.waitForExistence(timeout: 3) {
                matchTab.tap()
                sleep(5)
                snap("03_business_match_feed")
            }

            // Check feed content
            let skipBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skip this profile'")).firstMatch
            let feedHasContent = skipBtn.waitForExistence(timeout: 8)
            snap("03_business_sees_bloggers_\(feedHasContent)")

            // Go to Chats tab
            let chatsTab = app.tabBars.buttons["Chats"]
            if chatsTab.waitForExistence(timeout: 3) {
                chatsTab.tap()
                sleep(4)
                snap("03_business_chats")
            }

            // Verify Profile tab loads for business
            if profileTab.waitForExistence(timeout: 3) {
                profileTab.tap()
                sleep(3)
                snap("03_business_profile")
            }
        }
    }

    // MARK: - Test 4: Onboarding Cleanliness

    func test04_OnboardingCleanliness() throws {
        app.launch()
        sleep(10)

        // Sign out first
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
            sleep(3)

            let signOutBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Sign Out'")).firstMatch
            for _ in 0..<4 {
                if signOutBtn.exists { break }
                app.swipeUp()
                sleep(1)
            }
            if signOutBtn.waitForExistence(timeout: 3) {
                signOutBtn.tap()
                sleep(4)
            }
        }
        snap("04_signed_out")

        // Verify welcome screen content
        let matchaLogo = app.staticTexts.matching(NSPredicate(format: "label == 'MATCHA'")).firstMatch
        XCTAssertTrue(matchaLogo.waitForExistence(timeout: 8), "MATCHA logo text not found on welcome screen")

        let tagline = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Brew connections'")).firstMatch
        XCTAssertTrue(tagline.waitForExistence(timeout: 3), "Tagline 'Brew connections. Blend success.' not found")

        let getStartedBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Get started'")).firstMatch
        XCTAssertTrue(getStartedBtn.waitForExistence(timeout: 3), "Get Started button not found")

        let loginBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Log in to existing account'")).firstMatch
        XCTAssertTrue(loginBtn.waitForExistence(timeout: 3), "'I already have an account' button not found")

        snap("04_welcome_screen_verified")

        // NEGATIVE CHECKS — these should NOT appear on welcome screen (step 0)
        let joinBanner = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Join 200'")).firstMatch
        XCTAssertFalse(joinBanner.exists, "BUG: 'Join 200+' social proof text should NOT appear on welcome screen")

        let fastEntry = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Fast entry'")).firstMatch
        XCTAssertFalse(fastEntry.exists, "BUG: 'Fast entry' text should NOT appear on welcome screen")

        let shadowMode = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Shadow mode'")).firstMatch
        XCTAssertFalse(shadowMode.exists, "BUG: 'Shadow mode' text should NOT appear on welcome screen")

        let fastLogin = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Fast login'")).firstMatch
        XCTAssertFalse(fastLogin.exists, "BUG: 'Fast login' text should NOT appear on welcome screen (step 0)")

        let twoSteps = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2 steps'")).firstMatch
        XCTAssertFalse(twoSteps.exists, "BUG: '2 steps' text should NOT appear on welcome screen (step 0)")

        let stepIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Step 1'")).firstMatch
        XCTAssertFalse(stepIndicator.exists, "BUG: Step progress indicator should NOT appear on welcome screen")

        snap("04_negative_checks_done")
    }

    // MARK: - Test 5: All Tabs Work

    func test05_AllTabsWork() throws {
        app.launch()
        sleep(10)
        snap("05_app_launched")

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8), "Tab bar not found after app launch")

        // Offers tab
        let offersTab = app.tabBars.buttons["Offers"]
        XCTAssertTrue(offersTab.waitForExistence(timeout: 5), "Offers tab not found")
        offersTab.tap()
        sleep(3)
        snap("05_offers_tab")
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App crashed after tapping Offers tab")

        // Match tab
        let matchTab = app.tabBars.buttons["Match"]
        XCTAssertTrue(matchTab.waitForExistence(timeout: 3), "Match tab not found")
        matchTab.tap()
        sleep(5)
        snap("05_match_tab")
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App crashed after tapping Match tab")

        // Chats tab
        let chatsTab = app.tabBars.buttons["Chats"]
        XCTAssertTrue(chatsTab.waitForExistence(timeout: 3), "Chats tab not found")
        chatsTab.tap()
        sleep(4)
        snap("05_chats_tab")
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App crashed after tapping Chats tab")

        // Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 3), "Profile tab not found")
        profileTab.tap()
        sleep(3)
        snap("05_profile_tab")
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App crashed after tapping Profile tab")

        // Verify profile has Sign Out visible (proof it loaded)
        let signOutVisible = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Sign Out'")).firstMatch
        for _ in 0..<3 {
            if signOutVisible.exists { break }
            app.swipeUp()
            sleep(1)
        }
        XCTAssertTrue(signOutVisible.exists, "Profile tab has no Sign Out — may not have loaded")
        snap("05_all_tabs_done")
    }

    // MARK: - Helpers

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Register an account on the backend via HTTP. Ignores 409 (already exists).
    private func registerAccountOnBackend(email: String, password: String, role: String, fullName: String) {
        let url = URL(string: "http://188.253.19.166:8842/api/v1/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "role": role,
            "full_name": fullName,
            "primary_photo_url": "https://example.com/photo.jpg",
            "category": role == "business" ? "restaurant" : NSNull()
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse {
                print("[FlowTest] Pre-register \(email): HTTP \(http.statusCode)")
            }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 10)
    }
}
