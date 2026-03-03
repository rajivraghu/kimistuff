import Foundation

/// Represents a single meal entry with food items and protein content
struct MealEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var mealType: MealType
    var items: [FoodItem]
    var timestamp: Date
    
    init(id: UUID = UUID(), mealType: MealType, items: [FoodItem] = [], timestamp: Date = Date()) {
        self.id = id
        self.mealType = mealType
        self.items = items
        self.timestamp = timestamp
    }
    
    /// Total protein in this meal
    var totalProtein: Double {
        items.reduce(0) { $0 + $1.protein }
    }
    
    /// Check if this meal has protein entered
    var hasProteinEntry: Bool {
        !items.isEmpty
    }
}

/// Types of meals throughout the day
enum MealType: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .morning: return "sun.horizon.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }
    
    var timeRange: String {
        switch self {
        case .morning: return "6 AM - 10 AM"
        case .afternoon: return "12 PM - 2 PM"
        case .evening: return "5 PM - 8 PM"
        case .night: return "9 PM - 11 PM"
        }
    }
}

/// Individual food item with protein content
struct FoodItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var protein: Double // in grams
    
    init(id: UUID = UUID(), name: String, protein: Double) {
        self.id = id
        self.name = name
        self.protein = protein
    }
}

/// Daily log containing all meals for a day
struct DayLog: Identifiable, Codable {
    let id: UUID
    var date: Date
    var meals: [MealType: MealEntry]
    var dailyProteinGoal: Double
    
    init(id: UUID = UUID(), date: Date = Date(), dailyProteinGoal: Double = 120.0) {
        self.id = id
        self.date = date
        self.dailyProteinGoal = dailyProteinGoal
        
        // Initialize empty meals for all meal types
        var mealDict: [MealType: MealEntry] = [:]
        for mealType in MealType.allCases {
            mealDict[mealType] = MealEntry(mealType: mealType)
        }
        self.meals = mealDict
    }
    
    /// Total protein for the day
    var totalProtein: Double {
        meals.values.reduce(0) { $0 + $1.totalProtein }
    }
    
    /// Progress towards daily goal (0.0 to 1.0+)
    var progress: Double {
        dailyProteinGoal > 0 ? totalProtein / dailyProteinGoal : 0
    }
    
    /// Check if all meals have protein entries
    var isComplete: Bool {
        meals.values.allSatisfy { $0.hasProteinEntry }
    }
    
    /// Meals that are missing protein entries
    var missingMeals: [MealType] {
        MealType.allCases.filter { mealType in
            guard let meal = meals[mealType] else { return true }
            return !meal.hasProteinEntry
        }
    }
}
