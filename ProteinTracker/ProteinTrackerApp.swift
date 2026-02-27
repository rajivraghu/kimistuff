import SwiftUI

@main
struct ProteinTrackerApp: App {
    @StateObject private var viewModel = ProteinTrackerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
