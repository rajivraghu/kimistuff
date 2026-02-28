import SwiftUI

struct ContentView: View {
    var store: ReminderStore
    @State private var showingAddSheet = false
    @State private var editingReminder: Reminder?
    @Namespace private var namespace

    private var upcomingReminders: [Reminder] {
        store.reminders
            .filter { $0.isEnabled }
            .sorted { $0.date < $1.date }
    }

    private var pastReminders: [Reminder] {
        store.reminders
            .filter { !$0.isEnabled }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background for Liquid Glass to refract
                LinearGradient(
                    colors: [.blue.opacity(0.15), .purple.opacity(0.1), .pink.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if store.reminders.isEmpty {
                    emptyStateView
                } else {
                    reminderList
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddReminderView(store: store)
            }
            .sheet(item: $editingReminder) { reminder in
                AddReminderView(store: store, existingReminder: reminder)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Reminders")
                    .font(.title2.weight(.semibold))
                Text("Tap + to create your first reminder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Reminder", systemImage: "plus")
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
        }
    }

    // MARK: - Reminder List

    private var reminderList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !upcomingReminders.isEmpty {
                    sectionHeader("Upcoming")

                    GlassEffectContainer(spacing: 12) {
                        ForEach(upcomingReminders) { reminder in
                            reminderCard(reminder)
                                .glassEffectID(reminder.id.uuidString, in: namespace)
                        }
                    }
                }

                if !pastReminders.isEmpty {
                    sectionHeader("Completed")

                    GlassEffectContainer(spacing: 12) {
                        ForEach(pastReminders) { reminder in
                            reminderCard(reminder)
                                .opacity(0.7)
                                .glassEffectID("past-\(reminder.id.uuidString)", in: namespace)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Reminder Card

    private func reminderCard(_ reminder: Reminder) -> some View {
        HStack(spacing: 16) {
            // Toggle button
            Button {
                Task {
                    withAnimation(.spring(duration: 0.4)) {
                        Task { await store.toggleReminder(reminder) }
                    }
                }
            } label: {
                Image(systemName: reminder.isEnabled ? "alarm.fill" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(reminder.isEnabled ? .blue : .green)
                    .frame(width: 44, height: 44)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(!reminder.isEnabled, color: .secondary)

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(reminder.timeString)
                        .font(.caption)

                    if !reminder.repeatDays.isEmpty {
                        Text("·")
                        Text(reminder.repeatDescription)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)

                if !reminder.note.isEmpty {
                    Text(reminder.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions menu
            Menu {
                Button {
                    editingReminder = reminder
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    withAnimation(.spring(duration: 0.3)) {
                        store.deleteReminder(reminder)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

#Preview {
    ContentView(store: ReminderStore())
}
