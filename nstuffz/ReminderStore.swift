import Foundation
import SwiftUI
import AlarmKit
import AppIntents

// MARK: - Alarm Metadata

struct ReminderMetadata: AlarmMetadata {
    var reminderTitle: String
    var reminderNote: String

    init(reminderTitle: String = "", reminderNote: String = "") {
        self.reminderTitle = reminderTitle
        self.reminderNote = reminderNote
    }
}

// MARK: - App Intents for AlarmKit

struct StopReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Reminder"

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct SnoozeReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze Reminder"

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Reminder Store

@Observable
final class ReminderStore {
    var reminders: [Reminder] = [] {
        didSet { saveReminders() }
    }

    var quickNotes: [QuickNote] = [] {
        didSet { saveNotes() }
    }

    private let alarmManager = AlarmManager.shared
    private let saveKey = "saved_reminders"
    private let notesSaveKey = "saved_quick_notes"
    private let syncService = FirebaseSyncService()

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = decoded
        }
        if let data = UserDefaults.standard.data(forKey: notesSaveKey),
           let decoded = try? JSONDecoder().decode([QuickNote].self, from: data) {
            quickNotes = decoded
        }
    }

    private func saveReminders() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private func saveNotes() {
        guard let data = try? JSONEncoder().encode(quickNotes) else { return }
        UserDefaults.standard.set(data, forKey: notesSaveKey)
    }

    // MARK: - Authorization

    func requestAlarmAuthorization() async -> Bool {
        do {
            let state = try await alarmManager.requestAuthorization()
            print("AlarmKit authorization state: \(state)")
            return state == .authorized
        } catch {
            print("AlarmKit authorization error: \(error)")
            return false
        }
    }

    // MARK: - CRUD

    func addReminder(_ reminder: Reminder) async {
        reminders.append(reminder)
        if reminder.isEnabled {
            await scheduleAlarm(for: reminder)
        }
        // Sync to Firebase
        await syncToCloud(reminder)
    }

    func updateReminder(_ reminder: Reminder) async {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        // Cancel the old alarm first
        cancelAlarm(for: reminders[index])
        reminders[index] = reminder
        reminders[index].isSynced = false
        if reminder.isEnabled {
            await scheduleAlarm(for: reminder)
        }
        // Sync to Firebase
        await syncToCloud(reminders[index])
    }

    func deleteReminder(_ reminder: Reminder) {
        cancelAlarm(for: reminder)
        reminders.removeAll { $0.id == reminder.id }
        // Delete from Firebase
        Task { await syncService.deleteReminder(id: reminder.id) }
    }

    func deleteReminders(at offsets: IndexSet) {
        let toDelete = offsets.map { reminders[$0] }
        for reminder in toDelete {
            cancelAlarm(for: reminder)
        }
        reminders.remove(atOffsets: offsets)
        // Delete from Firebase
        Task {
            for reminder in toDelete {
                await syncService.deleteReminder(id: reminder.id)
            }
        }
    }

    func toggleReminder(_ reminder: Reminder) async {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isEnabled.toggle()
        reminders[index].isSynced = false
        if reminders[index].isEnabled {
            await scheduleAlarm(for: reminders[index])
        } else {
            cancelAlarm(for: reminders[index])
        }
        // Sync to Firebase
        await syncToCloud(reminders[index])
    }

    // MARK: - Quick Notes CRUD

    func addNote(_ note: QuickNote) async {
        quickNotes.insert(note, at: 0)
        await syncNoteToCloud(note)
    }

    func updateNote(_ note: QuickNote) async {
        guard let index = quickNotes.firstIndex(where: { $0.id == note.id }) else { return }
        quickNotes[index] = note
        quickNotes[index].isSynced = false
        await syncNoteToCloud(quickNotes[index])
    }

    func deleteNote(_ note: QuickNote) {
        quickNotes.removeAll { $0.id == note.id }
        Task { await syncService.deleteNote(id: note.id) }
    }

    // MARK: - Cloud Sync

    /// Sync a single reminder to Firebase and mark it as synced.
    private func syncToCloud(_ reminder: Reminder) async {
        let success = await syncService.syncReminder(reminder)
        if success, let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isSynced = true
        }
    }

    /// Sync a single note to Firebase and mark it as synced.
    private func syncNoteToCloud(_ note: QuickNote) async {
        let success = await syncService.syncNote(note)
        if success, let index = quickNotes.firstIndex(where: { $0.id == note.id }) {
            quickNotes[index].isSynced = true
        }
    }

    /// Called on app launch — syncs all unsynced reminders/notes and fetches from cloud.
    func syncOnLaunch() async {
        // First, push any unsynced local reminders to Firestore
        let unsynced = reminders.filter { !$0.isSynced }
        if !unsynced.isEmpty {
            let syncedIDs = await syncService.syncAllReminders(unsynced)
            for i in reminders.indices {
                if syncedIDs.contains(reminders[i].id) {
                    reminders[i].isSynced = true
                }
            }
        }

        // Then fetch all cloud reminders and merge any missing ones
        let cloudReminders = await syncService.fetchAllReminders()
        let localIDs = Set(reminders.map { $0.id })
        for cloudReminder in cloudReminders {
            if !localIDs.contains(cloudReminder.id) {
                reminders.append(cloudReminder)
                if cloudReminder.isEnabled {
                    await scheduleAlarm(for: cloudReminder)
                }
            }
        }

        // Sync any remaining local-only reminders that were already synced
        let cloudIDs = Set(cloudReminders.map { $0.id })
        let localOnly = reminders.filter { !$0.isSynced && !cloudIDs.contains($0.id) }
        if !localOnly.isEmpty {
            let syncedIDs = await syncService.syncAllReminders(localOnly)
            for i in reminders.indices {
                if syncedIDs.contains(reminders[i].id) {
                    reminders[i].isSynced = true
                }
            }
        }

        // Sync quick notes
        let unsyncedNotes = quickNotes.filter { !$0.isSynced }
        if !unsyncedNotes.isEmpty {
            let syncedIDs = await syncService.syncAllNotes(unsyncedNotes)
            for i in quickNotes.indices {
                if syncedIDs.contains(quickNotes[i].id) {
                    quickNotes[i].isSynced = true
                }
            }
        }

        // Fetch cloud notes and merge
        let cloudNotes = await syncService.fetchAllNotes()
        let localNoteIDs = Set(quickNotes.map { $0.id })
        for cloudNote in cloudNotes {
            if !localNoteIDs.contains(cloudNote.id) {
                quickNotes.append(cloudNote)
            }
        }
    }

    // MARK: - AlarmKit Scheduling

    private func scheduleAlarm(for reminder: Reminder) async {
        // Build the alert presentation with a snooze button
        let snoozeButton = AlarmButton(text: "Snooze", textColor: .blue, systemImageName: "clock.arrow.circlepath")
        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: reminder.title),
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .countdown
        )

        // Countdown state shown during snooze period
        let countdownContent = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: "Snoozed: \(reminder.title)")
        )

        let presentation = AlarmPresentation(alert: alertContent, countdown: countdownContent)

        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: ReminderMetadata(reminderTitle: reminder.title, reminderNote: reminder.note),
            tintColor: .blue
        )

        // Build the schedule
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminder.date)
        let minute = calendar.component(.minute, from: reminder.date)
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)

        let schedule: Alarm.Schedule
        if reminder.repeatDays.isEmpty {
            // One-time alarm: use .relative with .never recurrence
            schedule = .relative(.init(time: time, repeats: .never))
        } else {
            let weekdays: [Locale.Weekday] = reminder.repeatDays.sorted().compactMap { dayNumber in
                switch dayNumber {
                case 1: return .sunday
                case 2: return .monday
                case 3: return .tuesday
                case 4: return .wednesday
                case 5: return .thursday
                case 6: return .friday
                case 7: return .saturday
                default: return nil
                }
            }
            schedule = .relative(.init(time: time, repeats: .weekly(weekdays)))
        }

        // Use the init form with countdownDuration for snooze support (5 min snooze)
        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: Alarm.CountdownDuration(preAlert: nil, postAlert: 5 * 60),
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopReminderIntent(alarmID: reminder.id.uuidString),
            secondaryIntent: SnoozeReminderIntent(alarmID: reminder.id.uuidString)
        )

        do {
            let alarm = try await alarmManager.schedule(id: reminder.id, configuration: configuration)
            print("Alarm scheduled successfully: \(alarm.id), state: \(alarm.state)")
        } catch {
            print("Failed to schedule alarm for '\(reminder.title)': \(error)")
        }
    }

    private func cancelAlarm(for reminder: Reminder) {
        do {
            try alarmManager.cancel(id: reminder.id)
        } catch {
            // Alarm may not exist, that's fine
        }
    }

    // MARK: - Observe Alarm Updates

    func observeAlarmUpdates() async {
        for await alarms in alarmManager.alarmUpdates {
            let activeIDs = Set(alarms.map { $0.id })
            for i in reminders.indices {
                if reminders[i].isEnabled && !activeIDs.contains(reminders[i].id) && reminders[i].repeatDays.isEmpty && reminders[i].date < Date() {
                    reminders[i].isEnabled = false
                }
            }
        }
    }
}
