import Foundation
import FirebaseFirestore

/// Handles syncing reminders to/from Firebase Firestore.
@Observable
final class FirebaseSyncService {
    private var db: Firestore { Firestore.firestore() }
    private let collection = "alaraminder"

    // MARK: - Firestore Document Mapping

    private func reminderToData(_ reminder: Reminder) -> [String: Any] {
        [
            "id": reminder.id.uuidString,
            "title": reminder.title,
            "note": reminder.note,
            "date": Timestamp(date: reminder.date),
            "isEnabled": reminder.isEnabled,
            "repeatDays": Array(reminder.repeatDays).sorted()
        ]
    }

    private func dataToReminder(_ data: [String: Any]) -> Reminder? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let isEnabled = data["isEnabled"] as? Bool else {
            return nil
        }

        let note = data["note"] as? String ?? ""
        let repeatDaysArray = data["repeatDays"] as? [Int] ?? []

        return Reminder(
            id: id,
            title: title,
            note: note,
            date: timestamp.dateValue(),
            isEnabled: isEnabled,
            repeatDays: Set(repeatDaysArray),
            isSynced: true
        )
    }

    // MARK: - Sync Operations

    /// Upload or update a single reminder to Firestore.
    func syncReminder(_ reminder: Reminder) async -> Bool {
        do {
            try await db.collection(collection)
                .document(reminder.id.uuidString)
                .setData(reminderToData(reminder))
            print("Synced reminder '\(reminder.title)' to Firestore")
            return true
        } catch {
            print("Failed to sync reminder '\(reminder.title)': \(error)")
            return false
        }
    }

    /// Delete a reminder from Firestore.
    func deleteReminder(id: UUID) async {
        do {
            try await db.collection(collection)
                .document(id.uuidString)
                .delete()
            print("Deleted reminder \(id) from Firestore")
        } catch {
            print("Failed to delete reminder \(id) from Firestore: \(error)")
        }
    }

    /// Fetch all reminders from Firestore.
    func fetchAllReminders() async -> [Reminder] {
        do {
            let snapshot = try await db.collection(collection).getDocuments()
            let reminders = snapshot.documents.compactMap { doc in
                dataToReminder(doc.data())
            }
            print("Fetched \(reminders.count) reminders from Firestore")
            return reminders
        } catch {
            print("Failed to fetch reminders from Firestore: \(error)")
            return []
        }
    }

    /// Sync all local reminders to Firestore. Returns IDs of successfully synced reminders.
    func syncAllReminders(_ reminders: [Reminder]) async -> Set<UUID> {
        var syncedIDs = Set<UUID>()
        for reminder in reminders {
            let success = await syncReminder(reminder)
            if success {
                syncedIDs.insert(reminder.id)
            }
        }
        return syncedIDs
    }

    // MARK: - Quick Notes Sync

    private let notesCollection = "alaraminder_notes"

    private func noteToData(_ note: QuickNote) -> [String: Any] {
        [
            "id": note.id.uuidString,
            "text": note.text,
            "createdAt": Timestamp(date: note.createdAt)
        ]
    }

    private func dataToNote(_ data: [String: Any]) -> QuickNote? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let text = data["text"] as? String,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        return QuickNote(id: id, text: text, createdAt: timestamp.dateValue(), isSynced: true)
    }

    func syncNote(_ note: QuickNote) async -> Bool {
        do {
            try await db.collection(notesCollection)
                .document(note.id.uuidString)
                .setData(noteToData(note))
            print("Synced note to Firestore")
            return true
        } catch {
            print("Failed to sync note: \(error)")
            return false
        }
    }

    func deleteNote(id: UUID) async {
        do {
            try await db.collection(notesCollection)
                .document(id.uuidString)
                .delete()
            print("Deleted note \(id) from Firestore")
        } catch {
            print("Failed to delete note \(id) from Firestore: \(error)")
        }
    }

    func fetchAllNotes() async -> [QuickNote] {
        do {
            let snapshot = try await db.collection(notesCollection).getDocuments()
            let notes = snapshot.documents.compactMap { doc in
                dataToNote(doc.data())
            }
            print("Fetched \(notes.count) notes from Firestore")
            return notes
        } catch {
            print("Failed to fetch notes from Firestore: \(error)")
            return []
        }
    }

    func syncAllNotes(_ notes: [QuickNote]) async -> Set<UUID> {
        var syncedIDs = Set<UUID>()
        for note in notes {
            let success = await syncNote(note)
            if success {
                syncedIDs.insert(note.id)
            }
        }
        return syncedIDs
    }
}
