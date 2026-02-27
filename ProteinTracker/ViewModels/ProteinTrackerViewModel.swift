import Foundation

@MainActor
class ProteinTrackerViewModel: ObservableObject {
    @Published var entries: [ProteinEntry] = []
    @Published var dailyGoal: Double = 150.0
    @Published var selectedDate: Date = Date()
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "proteinEntries"
    private let goalKey = "dailyProteinGoal"
    
    var todaysEntries: [ProteinEntry] {
        entries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }
    
    var todaysTotal: Double {
        todaysEntries.reduce(0) { $0 + $1.amount }
    }
    
    var progressPercentage: Double {
        min(todaysTotal / dailyGoal, 1.0)
    }
    
    var remainingAmount: Double {
        max(dailyGoal - todaysTotal, 0)
    }
    
    init() {
        loadEntries()
        loadGoal()
    }
    
    func addEntry(amount: Double, source: String, notes: String? = nil) {
        let entry = ProteinEntry(amount: amount, source: source, notes: notes)
        entries.append(entry)
        saveEntries()
    }
    
    func deleteEntry(_ entry: ProteinEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func updateGoal(_ newGoal: Double) {
        dailyGoal = newGoal
        userDefaults.set(newGoal, forKey: goalKey)
    }
    
    func entriesForDate(_ date: Date) -> [ProteinEntry] {
        entries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func weeklyTotals() -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return (date: today, total: 0)
            }
            let total = entriesForDate(date).reduce(0) { $0 + $1.amount }
            return (date: date, total: total)
        }.reversed()
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        guard let data = userDefaults.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([ProteinEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
    
    private func loadGoal() {
        dailyGoal = userDefaults.double(forKey: goalKey)
        if dailyGoal == 0 {
            dailyGoal = 150.0
        }
    }
}
