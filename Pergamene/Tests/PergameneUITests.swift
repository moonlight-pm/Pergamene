import XCTest

class PergameneUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testSettingsPanelPullDown() throws {
        // Wait for the main content to load
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        // Perform a pull-down gesture from the top
        scrollView.swipeDown(velocity: .slow)
        
        // Wait a moment for animation
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check if settings are visible (look for the Settings title)
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.exists, "Settings panel should be visible after pull-down")
    }
    
    func testSettingsPanelPushUp() throws {
        // First show the settings
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        scrollView.swipeDown(velocity: .slow)
        Thread.sleep(forTimeInterval: 0.5)
        
        // Now push settings back up
        scrollView.swipeUp(velocity: .slow)
        Thread.sleep(forTimeInterval: 0.5)
        
        // Settings should be hidden again
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertFalse(settingsTitle.exists, "Settings panel should be hidden after push-up")
    }
    
    func testVerseNumberToggle() throws {
        // Show settings
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        scrollView.swipeDown(velocity: .slow)
        Thread.sleep(forTimeInterval: 0.5)
        
        // Find and toggle the verse numbers switch
        let verseSwitch = app.switches["Show Verse Numbers"]
        XCTAssertTrue(verseSwitch.exists, "Verse number switch should exist")
        
        // Remember initial state
        let initialValue = verseSwitch.value as? String == "1"
        
        // Toggle the switch
        verseSwitch.tap()
        
        // Verify the switch changed
        let newValue = verseSwitch.value as? String == "1"
        XCTAssertNotEqual(initialValue, newValue, "Switch value should change after tap")
        
        // Hide settings
        scrollView.swipeUp(velocity: .slow)
        Thread.sleep(forTimeInterval: 0.5)
        
        // TODO: Verify verse numbers visibility changed in the content
        // This would require checking for verse number labels in the content
    }
    
    func testChapterNavigation() throws {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        // Swipe left to go to next chapter
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify we're not showing settings (should be at top of new chapter)
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertFalse(settingsTitle.exists, "Settings should not be visible after chapter change")
        
        // Swipe right to go back
        scrollView.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Still shouldn't show settings
        XCTAssertFalse(settingsTitle.exists, "Settings should not be visible after chapter change back")
    }
    
    func testElasticPullResistance() throws {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        
        // Perform a small pull that shouldn't trigger settings
        let startCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let endCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate, withVelocity: .slow, thenHoldForDuration: 0)
        Thread.sleep(forTimeInterval: 0.3)
        
        // Settings should not be visible
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertFalse(settingsTitle.exists, "Small pull should not trigger settings")
        
        // Perform a larger pull that should trigger settings
        let largeEndCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        startCoordinate.press(forDuration: 0.1, thenDragTo: largeEndCoordinate, withVelocity: .slow, thenHoldForDuration: 0)
        Thread.sleep(forTimeInterval: 0.5)
        
        // Settings should now be visible
        XCTAssertTrue(settingsTitle.exists, "Large pull should trigger settings")
    }
}

// Helper extension for more precise gestures
extension XCUIElement {
    func swipeDown(velocity: XCUIGestureVelocity) {
        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let endCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate, withVelocity: velocity, thenHoldForDuration: 0)
    }
    
    func swipeUp(velocity: XCUIGestureVelocity) {
        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let endCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate, withVelocity: velocity, thenHoldForDuration: 0)
    }
}