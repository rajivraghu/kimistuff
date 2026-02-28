import SwiftUI
import AlarmKit

@main
struct nstuffzApp: App {
    @State private var store = ReminderStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .task {
                    _ = await store.requestAlarmAuthorization()
                }
                .task {
                    await store.observeAlarmUpdates()
                }
        }
    }
}
