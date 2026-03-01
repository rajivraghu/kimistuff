import SwiftUI
import AVFoundation

struct VoiceInputView: View {
    var store: ReminderStore
    var autoStart: Bool = true
    @State private var geminiService = GeminiService()

    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingSession = AVAudioSession.sharedInstance()
    @State private var hasPermission = false
    @State private var permissionDenied = false
    @State private var hasAutoStarted = false

    @State private var parsedAlarm: ParsedAlarm?
    @State private var showConfirmation = false
    @State private var showSuccess = false
    @State private var successMessage = "Reminder Created!"
    @State private var pulseScale: CGFloat = 1.0
    @State private var isQuickStuff = false

    @Namespace private var namespace

    private var audioFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice_command.wav")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [.indigo.opacity(0.15), .blue.opacity(0.1), .cyan.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Quick Stuff toggle
                    quickStuffToggle

                    // Status area
                    statusView

                    // Microphone button
                    microphoneButton

                    // Hint text
                    hintText

                    Spacer()

                    // Parsed result / confirmation
                    if showConfirmation, let alarm = parsedAlarm {
                        confirmationCard(alarm)
                    }

                    // Error display
                    if let error = geminiService.errorMessage {
                        errorCard(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Voice")
            .onAppear {
                requestMicPermission()
                // Auto-start recording when the tab appears
                if autoStart && !hasAutoStarted && !isRecording && !geminiService.isProcessing && parsedAlarm == nil {
                    hasAutoStarted = true
                    // Small delay to let permission request complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if hasPermission && !isRecording {
                            startRecording()
                        }
                    }
                }
            }
            .onDisappear {
                // Reset so it auto-records again next time user opens this tab
                hasAutoStarted = false
                // Stop recording if user leaves the tab
                if isRecording {
                    audioRecorder?.stop()
                    audioRecorder = nil
                    isRecording = false
                }
            }
            .onChange(of: hasPermission) { _, granted in
                // If permission was just granted and we haven't auto-started yet, start recording
                if granted && autoStart && !hasAutoStarted && !isRecording && !geminiService.isProcessing && parsedAlarm == nil {
                    hasAutoStarted = true
                    startRecording()
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Quick Stuff Toggle

    private var quickStuffToggle: some View {
        HStack(spacing: 12) {
            Image(systemName: isQuickStuff ? "note.text" : "alarm.fill")
                .font(.body)
                .foregroundStyle(isQuickStuff ? .yellow : .blue)

            Text("Quick Stuff")
                .font(.subheadline.weight(.medium))

            Toggle("", isOn: $isQuickStuff)
                .labelsHidden()
                .tint(.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .capsule)
    }

    // MARK: - Status View

    @ViewBuilder
    private var statusView: some View {
        if geminiService.isProcessing {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Analyzing your voice...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if isRecording {
            VStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
                    .symbolEffect(.variableColor.iterative)
                Text("Listening...")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)
            }
        } else if !showConfirmation && parsedAlarm == nil {
            VStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Tap to speak")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Microphone Button

    private var microphoneButton: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isRecording ? pulseScale : 1.0)

                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                    .shadow(color: (isRecording ? Color.red : Color.blue).opacity(0.4), radius: 12)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
        .disabled(geminiService.isProcessing || permissionDenied)
        .opacity(geminiService.isProcessing ? 0.5 : 1.0)
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pulseScale = 1.0
                }
            }
        }
    }

    // MARK: - Hint Text

    @ViewBuilder
    private var hintText: some View {
        if permissionDenied {
            Text("Microphone access denied. Go to Settings > nstuffz to enable it.")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        } else if !isRecording && !geminiService.isProcessing && parsedAlarm == nil {
            VStack(spacing: 8) {
                Text("Try saying:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isQuickStuff {
                    Text("\"Pick up groceries on the way home\"")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                    Text("\"Call dentist about appointment\"")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                } else {
                    Text("\"Remind me about GYM at 8PM daily\"")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                    Text("\"Wake me up at 7AM on weekdays\"")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Confirmation Card

    private func confirmationCard(_ alarm: ParsedAlarm) -> some View {
        GlassEffectContainer {
            VStack(alignment: .leading, spacing: 16) {
                // Transcript
                VStack(alignment: .leading, spacing: 4) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\"\(alarm.transcript)\"")
                        .font(.body.italic())
                }

                Divider()

                // Parsed details
                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(alarm.title)
                                .font(.headline)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatTime(hour: alarm.hour, minute: alarm.minute))
                                .font(.headline.monospacedDigit())
                        }

                        Spacer()
                    }

                    HStack(spacing: 24) {
                        if let dateStr = formatDate(alarm) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(dateStr)
                                    .font(.subheadline.weight(.medium))
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repeat")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatRepeat(alarm.repeatDays))
                                .font(.subheadline)
                        }

                        Spacer()
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            parsedAlarm = nil
                            showConfirmation = false
                        }
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        createReminder(from: alarm)
                    } label: {
                        Text("Create Reminder")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .tint(.blue)
                }
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 20))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Error Card

    private func errorCard(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Dismiss") {
                geminiService.errorMessage = nil
            }
            .font(.caption.weight(.medium))
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: successMessage.contains("Note") ? "note.text" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(successMessage.contains("Note") ? .yellow : .green)
            Text(successMessage)
                .font(.title2.weight(.semibold))
        }
        .padding(40)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(duration: 0.3)) {
                    showSuccess = false
                }
            }
        }
    }

    // MARK: - Audio Recording

    private func requestMicPermission() {
        if #available(iOS 17, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    hasPermission = granted
                    permissionDenied = !granted
                }
            }
        }
    }

    private func startRecording() {
        guard hasPermission else {
            requestMicPermission()
            return
        }

        // Reset state
        parsedAlarm = nil
        showConfirmation = false
        geminiService.errorMessage = nil

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Recording failed: \(error)")
            geminiService.errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        // Send to Gemini
        Task {
            if isQuickStuff {
                // Quick Stuff mode — transcribe and save as note
                if let text = await geminiService.transcribeAudio(fileURL: audioFileURL), !text.isEmpty {
                    let note = QuickNote(text: text)
                    await store.addNote(note)
                    withAnimation(.spring(duration: 0.3)) {
                        successMessage = "Note Saved!"
                        showSuccess = true
                    }
                }
            } else {
                // Normal mode — parse as alarm
                if let result = await geminiService.processAudio(fileURL: audioFileURL) {
                    withAnimation(.spring(duration: 0.4)) {
                        parsedAlarm = result
                        showConfirmation = true
                    }
                }
            }
        }
    }

    // MARK: - Create Reminder

    private func createReminder(from alarm: ParsedAlarm) {
        var calendar = Calendar.current
        calendar.timeZone = .current

        var components: DateComponents

        // Check if Gemini returned a specific date (year/month/day > 0)
        let hasDate = (alarm.year ?? 0) > 0 && (alarm.month ?? 0) > 0 && (alarm.day ?? 0) > 0

        if hasDate {
            // Use the specific date from voice input
            components = DateComponents()
            components.year = alarm.year
            components.month = alarm.month
            components.day = alarm.day
            components.hour = alarm.hour
            components.minute = alarm.minute
            components.second = 0
        } else {
            // No specific date — use today
            components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = alarm.hour
            components.minute = alarm.minute
            components.second = 0
        }

        var reminderDate = calendar.date(from: components) ?? Date()

        // If the time is in the past and it's a one-time alarm with no specific future date, move to tomorrow
        if alarm.repeatDays.isEmpty && !hasDate && reminderDate < Date() {
            reminderDate = calendar.date(byAdding: .day, value: 1, to: reminderDate) ?? reminderDate
        }

        let reminder = Reminder(
            title: alarm.title,
            date: reminderDate,
            repeatDays: Set(alarm.repeatDays)
        )

        Task {
            await store.addReminder(reminder)
            withAnimation(.spring(duration: 0.3)) {
                parsedAlarm = nil
                showConfirmation = false
                successMessage = "Reminder Created!"
                showSuccess = true
            }
        }
    }

    // MARK: - Formatters

    private func formatTime(hour: Int, minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }

    private func formatDate(_ alarm: ParsedAlarm) -> String? {
        guard let year = alarm.year, let month = alarm.month, let day = alarm.day,
              year > 0, month > 0, day > 0 else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formatRepeat(_ days: [Int]) -> String {
        if days.isEmpty { return "Once" }
        if days.sorted() == [1, 2, 3, 4, 5, 6, 7] { return "Daily" }
        if days.sorted() == [2, 3, 4, 5, 6] { return "Weekdays" }
        if days.sorted() == [1, 7] { return "Weekends" }
        let symbols = Calendar.current.shortWeekdaySymbols
        return days.sorted().map { symbols[$0 - 1] }.joined(separator: ", ")
    }
}
