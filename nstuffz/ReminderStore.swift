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
        didSet { save() }
    }

    private let alarmManager = AlarmManager.shared
    private let saveKey = "saved_reminders"

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Reminder].self, from: data) else {
            return
        }
        reminders = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
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
    }

    func updateReminder(_ reminder: Reminder) async {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        // Cancel the old alarm first
        cancelAlarm(for: reminders[index])
        reminders[index] = reminder
        if reminder.isEnabled {
            await scheduleAlarm(for: reminder)
        }
    }

    func deleteReminder(_ reminder: Reminder) {
        cancelAlarm(for: reminder)
        reminders.removeAll { $0.id == reminder.id }
    }

    func deleteReminders(at offsets: IndexSet) {
        for index in offsets {
            cancelAlarm(for: reminders[index])
        }
        reminders.remove(atOffsets: offsets)
    }

    func toggleReminder(_ reminder: Reminder) async {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isEnabled.toggle()
        if reminders[index].isEnabled {
            await scheduleAlarm(for: reminders[index])
        } else {
            cancelAlarm(for: reminders[index])
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
