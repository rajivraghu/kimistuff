
import XCTest
@testable import HabitTracker

final class HabitTrackerModelTests: XCTestCase {
    
    var viewModel: HabitTrackerViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = HabitTrackerViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Meal Entry Tests
    
    func testMealEntryHasProtein() {
        let meal = MealEntry(mealType: .morning)
        XCTAssertFalse(meal.hasProteinEntry, "Empty meal should not have protein entry")
        
        let mealWithFood = MealEntry(
            mealType: .morning,
            items: [FoodItem(name: "Eggs", protein: 6)]
        )
        XCTAssertTrue(mealWithFood.hasProteinEntry, "Meal with food should have protein entry")
    }
    
    func testMealEntryTotalProtein() {
        let meal = MealEntry(
            mealType: .morning,
            items: [
                FoodItem(name: "Eggs", protein: 6),
                FoodItem(name: "Milk", protein: 8)
            ]
        )
        XCTAssertEqual(meal.totalProtein, 14, "Total protein should be sum of all items")
    }
    
    // MARK: - Day Log Tests
    
    func testDayLogInitialization() {
        let dayLog = DayLog(dailyProteinGoal: 100)
        
        XCTAssertEqual(dayLog.dailyProteinGoal, 100)
        XCTAssertEqual(dayLog.meals.count, 4, "Should have 4 meal types")
        XCTAssertEqual(dayLog.totalProtein, 0, "New day log should have 0 protein")
    }
    
    func testDayLogProgress() {
        var dayLog = DayLog(dailyProteinGoal: 100)
        
        // Add protein to morning meal
        var meal = dayLog.meals[.morning]!
        meal.items.append(FoodItem(name: "Eggs", protein: 25))
        dayLog.meals[.morning] = meal
        
        XCTAssertEqual(dayLog.totalProtein, 25)
        XCTAssertEqual(dayLog.progress, 0.25, "Progress should be 25%")
    }
    
    func testDayLogIsComplete() {
        var dayLog = DayLog(dailyProteinGoal: 100)
        
        XCTAssertFalse(dayLog.isComplete, "Day should not be complete without meals")
        
        // Add protein to all meals
        for mealType in MealType.allCases {
            var meal = dayLog.meals[mealType]!
            meal.items.append(FoodItem(name: "Test Food", protein: 10))
            dayLog.meals[mealType] = meal
        }
        
        XCTAssertTrue(dayLog.isComplete, "Day should be complete with all meals")
    }
    
    func testDayLogMissingMeals() {
        var dayLog = DayLog(dailyProteinGoal: 100)
        
        XCTAssertEqual(dayLog.missingMeals.count, 4, "All meals should be missing initially")
        
        // Add protein to morning only
        var meal = dayLog.meals[.morning]!
        meal.items.append(FoodItem(name: "Eggs", protein: 10))
        dayLog.meals[.morning] = meal
        
        XCTAssertEqual(dayLog.missingMeals.count, 3, "Morning should not be missing")
        XCTAssertTrue(dayLog.missingMeals.contains(.afternoon))
    }
    
    // MARK: - ViewModel Tests
    
    func testAddFoodItem() {
        viewModel.addFoodItem(to: .morning, name: "Chicken Breast", protein: 31)
        
        let meal = viewModel.getMealEntry(for: .morning)
        XCTAssertEqual(meal.items.count, 1)
        XCTAssertEqual(meal.items.first?.name, "Chicken Breast")
        XCTAssertEqual(meal.items.first?.protein, 31)
    }
    
    func testRemoveFoodItem() {
        viewModel.addFoodItem(to: .morning, name: "Eggs", protein: 6)
        viewModel.addFoodItem(to: .morning, name: "Milk", protein: 8)
        
        viewModel.removeFoodItem(from: .morning, at: 0)
        
        let meal = viewModel.getMealEntry(for: .morning)
        XCTAssertEqual(meal.items.count, 1)
        XCTAssertEqual(meal.items.first?.name, "Milk")
    }
    
    func testUpdateGoal() {
        viewModel.updateGoal(150)
        
        XCTAssertEqual(viewModel.dailyProteinGoal, 150)
    }
    
    func testProgressCalculation() {
        // Add some protein
        viewModel.addFoodItem(to: .morning, name: "Eggs", protein: 20)
        viewModel.addFoodItem(to: .afternoon, name: "Chicken", protein: 30)
        
        let expectedProgress = 50.0 / viewModel.dailyProteinGoal
        XCTAssertEqual(viewModel.progressPercentage, expectedProgress, accuracy: 0.01)
    }
    
    func testIsGoalMet() {
        XCTAssertFalse(viewModel.isGoalMet, "Goal should not be met initially")
        
        // Add enough protein to meet goal
        viewModel.updateGoal(50)
        viewModel.addFoodItem(to: .morning, name: "Protein Shake", protein: 50)
        
        XCTAssertTrue(viewModel.isGoalMet, "Goal should be met")
    }
    
    // MARK: - Meal Type Tests
    
    func testAllMealTypesExist() {
        XCTAssertEqual(MealType.allCases.count, 4)
        XCTAssertNotNil(MealType.morning.icon)
        XCTAssertNotNil(MealType.afternoon.icon)
        XCTAssertNotNil(MealType.evening.icon)
        XCTAssertNotNil(MealType.night.icon)
    }
}
