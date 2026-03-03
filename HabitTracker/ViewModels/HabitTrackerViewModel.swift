import Foundation
import SwiftUI

/// Main ViewModel for the Habit Tracker
@MainActor
class HabitTrackerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentDayLog: DayLog
    @Published var history: [DayLog] = []
    @Published var dailyProteinGoal: Double
    @Published var showingMealInput: Bool = false
    @Published var selectedMealType: MealType = .morning
    
    // MARK: - UserDefaults Keys
    private let goalKey = "habitTracker.dailyProteinGoal"
    private let historyKey = "habitTracker.history"
    private let lastDateKey = "habitTracker.lastDate"
    
    // MARK: - Initialization
    init() {
        // Load saved goal or use default
        let savedGoal = UserDefaults.standard.double(forKey: goalKey)
        self.dailyProteinGoal = savedGoal > 0 ? savedGoal : 120.0
        
        // Check if we need a new day
        self.currentDayLog = DayLog(dailyProteinGoal: self.dailyProteinGoal)
        
        // Load history
        loadHistory()
        
        // Check if today's log already exists
        checkAndLoadTodayLog()
    }
    
    // MARK: - Computed Properties
    var progressPercentage: Double {
        currentDayLog.progress
    }
    
    var todaysTotal: Double {
        currentDayLog.totalProtein
    }
    
    var remainingProtein: Double {
        max(0, dailyProteinGoal - currentDayLog.totalProtein)
    }
    
    var isGoalMet: Bool {
        currentDayLog.totalProtein >= dailyProteinGoal
    }
    
    var hasMissingMeals: Bool {
        !currentDayLog.missingMeals.isEmpty
    }
    
    // MARK: - Meal Management
    func addFoodItem(to mealType: MealType, name: String, protein: Double) {
        let foodItem = FoodItem(name: name, protein: protein)
        
        if var meal = currentDayLog.meals[mealType] {
            meal.items.append(foodItem)
            currentDayLog.meals[mealType] = meal
        }
        
        saveTodayLog()
    }
    
    func removeFoodItem(from mealType: MealType, at index: Int) {
        if var meal = currentDayLog.meals[mealType], index < meal.items.count {
            meal.items.remove(at: index)
            currentDayLog.meals[mealType] = meal
            saveTodayLog()
        }
    }
    
    func updateFoodItem(in mealType: MealType, at index: Int, name: String, protein: Double) {
        if var meal = currentDayLog.meals[mealType], index < meal.items.count {
            let newItem = FoodItem(name: name, protein: protein)
            meal.items[index] = newItem
            currentDayLog.meals[mealType] = meal
            saveTodayLog()
        }
    }
    
    func getMealEntry(for mealType: MealType) -> MealEntry {
        currentDayLog.meals[mealType] ?? MealEntry(mealType: mealType)
    }
    
    // MARK: - Day Management
    func updateGoal(_ newGoal: Double) {
        guard newGoal > 0 else { return }
        dailyProteinGoal = newGoal
        currentDayLog.dailyProteinGoal = newGoal
        UserDefaults.standard.set(newGoal, forKey: goalKey)
        saveTodayLog()
    }
    
    func resetToday() {
        currentDayLog = DayLog(dailyProteinGoal: dailyProteinGoal)
        saveTodayLog()
    }
    
    // MARK: - Persistence
    private func saveTodayLog() {
        currentDayLog.dailyProteinGoal = dailyProteinGoal
        UserDefaults.standard.set(currentDayLog.id.uuidString, forKey: lastDateKey)
        
        var updatedHistory = history.filter { !Calendar.current.isDate($0.date, inSameDayAs: currentDayLog.date) }
        updatedHistory.append(currentDayLog)
        
        // Keep only last 30 days
        if updatedHistory.count > 30 {
            updatedHistory = Array(updatedHistory.suffix(30))
        }
        
        history = updatedHistory
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([DayLog].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func checkAndLoadTodayLog() {
        let lastDateString = UserDefaults.standard.string(forKey: lastDateKey)
        
        if let lastDateUUID = lastDateString,
           let lastDateID = UUID(uuidString: lastDateString) {
            // Find today's log in history
            if let todayLog = history.first(where: { $0.id == lastDateID }) {
                var log = todayLog
                log.dailyProteinGoal = dailyProteinGoal
                currentDayLog = log
            }
        }
    }
    
    // MARK: - Statistics
    func weeklyProteinData() -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            
            let dayLog = history.first { calendar.isDate($0.date, inSameDayAs: date) }
            return (date: date, total: dayLog?.totalProtein ?? 0)
        }.reversed()
    }
    
    func averageProtein() -> Double {
        guard !history.isEmpty else { return 0 }
        let total = history.reduce(0) { $0 + $1.totalProtein }
        return total / Double(history.count)
    }
}
