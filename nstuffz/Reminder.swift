import Foundation

struct Reminder: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var note: String
    var date: Date
    var isEnabled: Bool
    var repeatDays: Set<Int> // Empty = one-time, otherwise weekday numbers (1=Sunday..7=Saturday)

    init(id: UUID = UUID(), title: String, note: String = "", date: Date, isEnabled: Bool = true, repeatDays: Set<Int> = []) {
        self.id = id
        self.title = title
        self.note = note
        self.date = date
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Once"
        }
        let daySymbols = Calendar.current.shortWeekdaySymbols
        let sorted = repeatDays.sorted()
        if sorted.count == 7 {
            return "Every day"
        }
        if sorted == [2, 3, 4, 5, 6] {
            return "Weekdays"
        }
        if sorted == [1, 7] {
            return "Weekends"
        }
        return sorted.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
}
