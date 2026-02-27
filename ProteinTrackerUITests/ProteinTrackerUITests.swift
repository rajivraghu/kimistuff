import XCTest

final class ProteinTrackerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testScreenshot_TodayTab() throws {
        // Wait for app to load
        sleep(2)
        takeScreenshot(named: "01_Today_Tab")
    }
    
    func testScreenshot_HistoryTab() throws {
        sleep(2)
        app.tabBars.buttons["History"].tap()
        sleep(1)
        takeScreenshot(named: "02_History_Tab")
    }
    
    func testScreenshot_SettingsTab() throws {
        sleep(2)
        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        takeScreenshot(named: "03_Settings_Tab")
    }
    
    func testScreenshot_AddEntrySheet() throws {
        sleep(2)
        app.navigationBars["Protein Tracker"].buttons["Add"].tap()
        sleep(1)
        takeScreenshot(named: "04_Add_Entry_Sheet")
        app.buttons["Cancel"].tap()
    }
    
    func testScreenshot_AfterQuickAdd() throws {
        sleep(2)
        // Tap first quick add button (+10g)
        let quickAddButton = app.buttons["+10g"]
        if quickAddButton.exists {
            quickAddButton.tap()
            sleep(1)
        }
        takeScreenshot(named: "05_After_Quick_Add")
    }
}
