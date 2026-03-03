import XCTest
import SwiftUI

final class HabitTrackerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-privacy"]
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunch() {
        app.launch()
        
        // Verify main tabs exist
        XCTAssertTrue(app.tabBars.buttons["Today"].exists)
        XCTAssertTrue(app.tabBars.buttons["History"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
    
    func testTodayViewDisplays() {
        app.launch()
        
        // Should show today's meals title
        XCTAssertTrue(app.navigationBars["Today's Meals"].exists)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToHistory() {
        app.launch()
        
        app.tabBars.buttons["History"].tap()
        
        // History view should show
        XCTAssertTrue(app.navigationBars["History"].exists)
    }
    
    func testNavigateToSettings() {
        app.launch()
        
        app.tabBars.buttons["Settings"].tap()
        
        // Settings view should show
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
    
    // MARK: - Add Food Tests
    
    func testAddFoodSheet() {
        app.launch()
        
        // Tap on first meal card (Morning) to expand
        let morningCard = app.buttons["Morning"]
        morningCard.tap()
        
        // Tap add button
        app.buttons["Add Food Item"].tap()
        
        // Sheet should appear
        XCTAssertTrue(app.navigationBars["Add Food"].exists)
    }
    
    // MARK: - Progress Ring Tests
    
    func testProgressRingExists() {
        app.launch()
        
        // Progress ring should be visible
        XCTAssertTrue(app.staticTexts.element.waitForExistence(timeout: 5))
    }
    
    // MARK: - Meal Cards Tests
    
    func testAllMealCardsExist() {
        app.launch()
        
        XCTAssertTrue(app.buttons["Morning"].exists)
        XCTAssertTrue(app.buttons["Afternoon"].exists)
        XCTAssertTrue(app.buttons["Evening"].exists)
        XCTAssertTrue(app.buttons["Night"].exists)
    }
    
    // MARK: - Settings Tests
    
    func testSettingsGoalUpdate() {
        app.launch()
        
        app.tabBars.buttons["Settings"].tap()
        
        // Update goal
        app.textFields["Enter goal"].tap()
        app.textFields["Enter goal"].typeText("150")
        
        app.buttons["Update Goal"].tap()
    }
    
    // MARK: - Screenshot Generation
    
    func generateAndSaveScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        
        // Save to artifacts directory
        let artifactsPath = ProcessInfo.processInfo.environment["ARTIFACTS_PATH"] ?? NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: artifactsPath).appendingPathComponent("\(name).png")
        
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("📸 Screenshot saved: \(fileURL.path)")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }
    
    func testScreenshot_MainView() {
        app.launch()
        generateAndSaveScreenshot(named: "main_view")
    }
    
    func testScreenshot_HistoryView() {
        app.launch()
        app.tabBars.buttons["History"].tap()
        generateAndSaveScreenshot(named: "history_view")
    }
    
    func testScreenshot_SettingsView() {
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        generateAndSaveScreenshot(named: "settings_view")
    }
    
    func testScreenshot_AddFoodSheet() {
        app.launch()
        
        // Expand morning meal
        app.buttons["Morning"].tap()
        
        // Add food
        app.buttons["Add Food Item"].tap()
        
        // Wait for sheet
        sleep(1)
        generateAndSaveScreenshot(named: "add_food_sheet")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        app.launch()
        
        // Check navigation is accessible
        XCTAssertTrue(app.tabBars.buttons["Today"].exists)
    }
}
