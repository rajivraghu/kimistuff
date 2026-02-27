import Foundation

struct ProteinEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var amount: Double
    var timestamp: Date
    var source: String
    var notes: String?
    
    init(id: UUID = UUID(), amount: Double, timestamp: Date = Date(), source: String, notes: String? = nil) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.source = source
        self.notes = notes
    }
}

extension ProteinEntry {
    var formattedAmount: String {
        String(format: "%.1f g", amount)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
