import XCTest
@testable import ProteinTracker

@MainActor
final class ProteinTrackerTests: XCTestCase {
    
    var viewModel: ProteinTrackerViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ProteinTrackerViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testAddEntry() {
        let initialCount = viewModel.entries.count
        viewModel.addEntry(amount: 25.0, source: "Test", notes: nil)
        XCTAssertEqual(viewModel.entries.count, initialCount + 1)
        XCTAssertEqual(viewModel.todaysTotal, 25.0)
    }
    
    func testDeleteEntry() {
        viewModel.addEntry(amount: 30.0, source: "Test", notes: nil)
        let entry = viewModel.entries.first!
        viewModel.deleteEntry(entry)
        XCTAssertFalse(viewModel.entries.contains { $0.id == entry.id })
    }
    
    func testProgressPercentage() {
        viewModel.updateGoal(100.0)
        viewModel.addEntry(amount: 50.0, source: "Test", notes: nil)
        XCTAssertEqual(viewModel.progressPercentage, 0.5)
    }
    
    func testRemainingAmount() {
        viewModel.updateGoal(100.0)
        viewModel.addEntry(amount: 30.0, source: "Test", notes: nil)
        XCTAssertEqual(viewModel.remainingAmount, 70.0)
    }
    
    func testGoalMet() {
        viewModel.updateGoal(50.0)
        viewModel.addEntry(amount: 60.0, source: "Test", notes: nil)
        XCTAssertEqual(viewModel.progressPercentage, 1.0)
        XCTAssertEqual(viewModel.remainingAmount, 0.0)
    }
}
