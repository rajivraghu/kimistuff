import SwiftUI
import AlarmKit
import FirebaseCore

enum AppTab: String {
    case reminders
    case voice
}

@main
struct nstuffzApp: App {
    @State private var store = ReminderStore()
    @State private var selectedTab: AppTab = .voice

    init() {
        KeychainHelper.bootstrapFromSecretsIfNeeded()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Tab("Reminders", systemImage: "alarm.fill", value: .reminders) {
                    ContentView(store: store)
                }
                Tab("Voice", systemImage: "mic.fill", value: .voice) {
                    VoiceInputView(store: store)
                }
            }
            .onOpenURL { url in
                if url.host() == "voice" {
                    selectedTab = .voice
                }
            }
            .task {
                _ = await store.requestAlarmAuthorization()
            }
            .task {
                await store.observeAlarmUpdates()
            }
            .task {
                await store.syncOnLaunch()
            }
        }
    }
}
