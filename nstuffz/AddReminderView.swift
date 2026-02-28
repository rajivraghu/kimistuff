import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    var store: ReminderStore
    var existingReminder: Reminder?

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date().addingTimeInterval(60 * 60)
    @State private var repeatDays: Set<Int> = []

    private var isEditing: Bool { existingReminder != nil }

    private let weekdays: [(id: Int, name: String)] = {
        let symbols = Calendar.current.shortWeekdaySymbols
        return (1...7).map { ($0, symbols[$0 - 1]) }
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title & Note
                        VStack(spacing: 12) {
                            TextField("Reminder title", text: $title)
                                .font(.title3.weight(.medium))
                                .padding()
                                .glassEffect(in: .rect(cornerRadius: 16))

                            TextField("Add a note (optional)", text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .padding()
                                .glassEffect(in: .rect(cornerRadius: 16))
                        }

                        // Date & Time Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            DatePicker("", selection: $date, in: Date()...)
                                .datePickerStyle(.graphical)
                                .padding()
                                .glassEffect(in: .rect(cornerRadius: 20))
                        }

                        // Repeat Days
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            GlassEffectContainer(spacing: 8) {
                                HStack(spacing: 8) {
                                    ForEach(weekdays, id: \.id) { day in
                                        Button {
                                            withAnimation(.spring(duration: 0.3)) {
                                                if repeatDays.contains(day.id) {
                                                    repeatDays.remove(day.id)
                                                } else {
                                                    repeatDays.insert(day.id)
                                                }
                                            }
                                        } label: {
                                            Text(day.name)
                                                .font(.caption.weight(.semibold))
                                                .frame(width: 40, height: 40)
                                        }
                                        .glassEffect(
                                            repeatDays.contains(day.id)
                                                ? .regular.tint(.blue).interactive()
                                                : .regular.interactive(),
                                            in: .circle
                                        )
                                        .foregroundStyle(repeatDays.contains(day.id) ? .white : .primary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let existing = existingReminder {
                    title = existing.title
                    note = existing.note
                    date = existing.date
                    repeatDays = existing.repeatDays
                }
            }
        }
    }

    private func saveReminder() {
        let reminder = Reminder(
            id: existingReminder?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            note: note.trimmingCharacters(in: .whitespaces),
            date: date,
            isEnabled: true,
            repeatDays: repeatDays
        )

        Task {
            if isEditing {
                await store.updateReminder(reminder)
            } else {
                await store.addReminder(reminder)
            }
        }
        dismiss()
    }
}
