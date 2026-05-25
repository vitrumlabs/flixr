import XCTest

@MainActor
final class SnapshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment = [
            "FIRAAppCheckDebugToken": "5E853C9A-CA12-4F80-8BF2-1B6E1F766951"
        ]
        app.launch()
    }

    func testScreenshots() throws {
        // ── 1. Welcome screen ────────────────────────────────────────────────
        // Wait for the app to finish loading and show the welcome screen
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 10))
        snapshot("01_Welcome")

        // ── 2. Navigate to sign-in form ──────────────────────────────────────
        signInButton.tap()

        // ── 3. Enter credentials ─────────────────────────────────────────────
        let email = ProcessInfo.processInfo.environment["SNAPSHOT_TEST_EMAIL"] ?? ""
        let password = ProcessInfo.processInfo.environment["SNAPSHOT_TEST_PASSWORD"] ?? ""

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["Sign In"].tap()

        // ── 4. Discovery / swipe screen ───────────────────────────────────────
        // Wait for the tab bar to appear — means we're in the main app
        let discoverTab = app.tabBars.buttons["Discover"]
        XCTAssertTrue(discoverTab.waitForExistence(timeout: 20))
        // Give the deck a moment to load movies
        sleep(3)
        snapshot("02_Discovery")

        // ── 5. Mood tab ───────────────────────────────────────────────────────
        app.tabBars.buttons["Mood"].tap()
        sleep(2)
        snapshot("03_Mood")

        // ── 6. Watchlist tab ──────────────────────────────────────────────────
        app.tabBars.buttons["Watchlist"].tap()
        sleep(1)
        snapshot("04_Watchlist")

        // ── 7. Profile sheet ──────────────────────────────────────────────────
        // Return to Discover, then open profile
        discoverTab.tap()
        sleep(1)
        app.buttons["Profile"].tap()
        sleep(1)
        snapshot("05_Profile")
    }
}
