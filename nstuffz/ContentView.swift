import SwiftUI

struct ContentView: View {
    var store: ReminderStore
    @State private var showingAddSheet = false
    @State private var editingReminder: Reminder?
    @State private var selectedNote: QuickNote?
    @State private var editedNoteText = ""
    @State private var showDeleteConfirmation = false
    @State private var noteToDelete: QuickNote?
    @Namespace private var namespace

    // Sticky note colors for visual variety
    private let stickyColors: [Color] = [.yellow, .orange, .green, .pink, .cyan, .mint]

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

                if store.reminders.isEmpty && store.quickNotes.isEmpty {
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
            .sheet(item: $selectedNote) { note in
                noteDetailSheet(note)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert("Delete Note?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    noteToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let note = noteToDelete {
                        withAnimation(.spring(duration: 0.3)) {
                            store.deleteNote(note)
                        }
                        noteToDelete = nil
                        selectedNote = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this note? This cannot be undone.")
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
                // Quick Notes (sticky notes)
                if !store.quickNotes.isEmpty {
                    sectionHeader("Quick Stuff")

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(store.quickNotes.enumerated()), id: \.element.id) { index, note in
                            stickyNoteCard(note, color: stickyColors[index % stickyColors.count])
                        }
                    }
                }

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
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(reminder.dateString)
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

            // Cloud sync status
            Image(systemName: reminder.isSynced ? "checkmark.icloud.fill" : "icloud.slash")
                .font(.caption)
                .foregroundStyle(reminder.isSynced ? .green : .orange)

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

    // MARK: - Sticky Note Card

    private func stickyNoteCard(_ note: QuickNote, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(color)
                    .rotationEffect(.degrees(-30))

                Spacer()

                // Sync status
                Image(systemName: note.isSynced ? "checkmark.icloud.fill" : "icloud.slash")
                    .font(.system(size: 8))
                    .foregroundStyle(note.isSynced ? .green : .orange)
            }

            Text(note.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Text(note.timeAgo)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(color.opacity(0.15), in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            editedNoteText = note.text
            selectedNote = note
        }
    }

    // MARK: - Note Detail Sheet

    private func noteDetailSheet(_ note: QuickNote) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Editable text area
                TextEditor(text: $editedNoteText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
                    .frame(minHeight: 150)

                // Time info
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(note.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: note.isSynced ? "checkmark.icloud.fill" : "icloud.slash")
                        .font(.caption)
                        .foregroundStyle(note.isSynced ? .green : .orange)
                }

                // Delete button
                Button(role: .destructive) {
                    noteToDelete = note
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Note")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()
            }
            .padding()
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedNote = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if editedNoteText != note.text {
                            var updated = note
                            updated.text = editedNoteText
                            Task { await store.updateNote(updated) }
                        }
                        selectedNote = nil
                    }
                    .fontWeight(.semibold)
                    .disabled(editedNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView(store: ReminderStore())
}
