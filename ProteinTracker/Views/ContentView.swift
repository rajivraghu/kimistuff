import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    @State private var showingAddEntry = false
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    @State private var showingAddEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ProgressRingView(
                        progress: viewModel.progressPercentage,
                        current: viewModel.todaysTotal,
                        goal: viewModel.dailyGoal
                    )
                    .frame(height: 200)
                    .padding()
                    
                    QuickAddView()
                    
                    TodayLogView()
                }
            }
            .navigationTitle("Protein Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(isPresented: $showingAddEntry)
            }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    
    var body: some View {
        NavigationView {
            WeeklyChartView()
                .navigationTitle("History")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    @State private var goalText: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Goal")) {
                    HStack {
                        TextField("Goal", text: $goalText)
                            .keyboardType(.decimalPad)
                        Text("g")
                    }
                    
                    Button("Update Goal") {
                        if let newGoal = Double(goalText), newGoal > 0 {
                            viewModel.updateGoal(newGoal)
                        }
                    }
                }
                
                Section(header: Text("Current Settings")) {
                    HStack {
                        Text("Daily Goal")
                        Spacer()
                        Text("\(Int(viewModel.dailyGoal))g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(viewModel.entries.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                goalText = String(Int(viewModel.dailyGoal))
            }
        }
    }
}
