import Foundation

// MARK: - Quick Note

struct QuickNote: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var createdAt: Date
    var isSynced: Bool

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isSynced: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isSynced = isSynced
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isSynced = (try? container.decode(Bool.self, forKey: .isSynced)) ?? false
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Reminder

struct Reminder: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var note: String
    var date: Date
    var isEnabled: Bool
    var repeatDays: Set<Int> // Empty = one-time, otherwise weekday numbers (1=Sunday..7=Saturday)
    var isSynced: Bool

    init(id: UUID = UUID(), title: String, note: String = "", date: Date, isEnabled: Bool = true, repeatDays: Set<Int> = [], isSynced: Bool = false) {
        self.id = id
        self.title = title
        self.note = note
        self.date = date
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.isSynced = isSynced
    }

    // Custom decoder to handle existing reminders saved without isSynced
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        note = try container.decode(String.self, forKey: .note)
        date = try container.decode(Date.self, forKey: .date)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        repeatDays = try container.decode(Set<Int>.self, forKey: .repeatDays)
        isSynced = (try? container.decode(Bool.self, forKey: .isSynced)) ?? false
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
