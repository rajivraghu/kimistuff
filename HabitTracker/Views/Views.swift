import SwiftUI

// MARK: - Main App Entry Point
@main
struct HabitTrackerApp: App {
    @StateObject private var viewModel = HabitTrackerViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var viewModel: HabitTrackerViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyHabitView()
                .tabItem {
                    Label("Today", systemImage: "calendar.circle.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear.circle.fill")
                }
                .tag(2)
        }
        .tint(Color(hex: "00d4ff"))
    }
}

// MARK: - Daily Habit View
struct DailyHabitView: View {
    @EnvironmentObject var viewModel: HabitTrackerViewModel
    @State private var showingAddFood = false
    @State private var selectedMealForInput: MealType = .morning
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Progress Ring
                        LiquidProgressRing(
                            progress: viewModel.progressPercentage,
                            current: viewModel.todaysTotal,
                            goal: viewModel.dailyProteinGoal
                        )
                        .frame(height: 220)
                        .padding(.top, 20)
                        
                        // Status Message
                        if viewModel.isGoalMet {
                            HStack {
                                Image(systemName: "trophy.fill")
                                Text("Daily Goal Achieved!")
                            }
                            .font(.headline)
                            .foregroundColor(Color(hex: "00ff88"))
                            .padding()
                            .liquidGlass(cornerRadius: 16, opacity: 0.2)
                        } else if viewModel.hasMissingMeals {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("\(viewModel.remainingProtein)g protein remaining")
                            }
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding()
                            .liquidGlass(cornerRadius: 16, opacity: 0.2)
                        }
                        
                        // Meal Cards
                        VStack(spacing: 16) {
                            ForEach(MealType.allCases) { mealType in
                                MealCard(
                                    mealType: mealType,
                                    mealEntry: viewModel.getMealEntry(for: mealType),
                                    onAddItem: {
                                        selectedMealForInput = mealType
                                        showingAddFood = true
                                    },
                                    onRemoveItem: { index in
                                        viewModel.removeFoodItem(from: mealType, at: index)
                                    }
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Today's Meals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.resetToday() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodItemView(mealType: selectedMealForInput, isPresented: $showingAddFood)
            }
        }
    }
}

// MARK: - Add Food Item View
struct AddFoodItemView: View {
    @EnvironmentObject var viewModel: HabitTrackerViewModel
    let mealType: MealType
    @Binding var isPresented: Bool
    
    @State private var foodName: String = ""
    @State private var proteinAmount: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackground()
                
                VStack(spacing: 20) {
                    // Meal Type Header
                    HStack {
                        Image(systemName: mealType.icon)
                            .font(.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "00d4ff"), Color(hex: "7b2cbf")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        VStack(alignment: .leading) {
                            Text(mealType.rawValue)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text(mealType.timeRange)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16, opacity: 0.15)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What did you eat?")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                            GlassTextField(placeholder: "e.g., Chicken Breast, Eggs, Dal", text: $foodName)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein (grams) *")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                            GlassTextField(placeholder: "e.g., 30", text: $proteinAmount, keyboardType: .decimalPad)
                        }
                        
                        // Protein info
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Protein intake is mandatory for tracking")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16, opacity: 0.15)
                    
                    Spacer()
                    
                    // Save Button
                    LiquidButton(title: "Save", icon: "checkmark.circle.fill") {
                        saveFoodItem()
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveFoodItem() {
        // Validate protein is entered
        guard let protein = Double(proteinAmount), protein > 0 else {
            errorMessage = "Please enter a valid protein amount (required)"
            showingError = true
            return
        }
        
        // Validate food name
        guard !foodName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter what you ate"
            showingError = true
            return
        }
        
        viewModel.addFoodItem(to: mealType, name: foodName.trimmingCharacters(in: .whitespaces), protein: protein)
        isPresented = false
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var viewModel: HabitTrackerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackground()
                
                if viewModel.history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No history yet")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                        Text("Start tracking your meals today!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.3))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Weekly Stats
                            HStack(spacing: 16) {
                                StatCard(title: "Average", value: "\(Int(viewModel.averageProtein()))g", subtitle: "per day")
                                StatCard(title: "Streak", value: "\(streakDays())", subtitle: "days")
                            }
                            .padding(.horizontal)
                            
                            // History List
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.history.sorted(by: { $0.date > $1.date })) { dayLog in
                                    HistoryCard(dayLog: dayLog)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
    
    private func streakDays() -> Int {
        let calendar = Calendar.current
        var streak = 0
        let sortedHistory = viewModel.history.sorted { $0.date > $1.date }
        
        for dayLog in sortedHistory {
            if dayLog.totalProtein >= viewModel.dailyProteinGoal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "00d4ff"), Color(hex: "7b2cbf")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .liquidGlass(cornerRadius: 16, opacity: 0.15)
    }
}

// MARK: - History Card
struct HistoryCard: View {
    let dayLog: DayLog
    @State private var isExpanded = false
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dayLog.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() }}) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("\(Int(dayLog.totalProtein))g")
                                .foregroundColor(Color(hex: "00d4ff"))
                            
                            if dayLog.isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "00ff88"))
                                    .font(.caption)
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.1), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: min(dayLog.progress, 1.0))
                            .stroke(
                                dayLog.progress >= 1.0 
                                    ? LinearGradient(colors: [Color(hex: "00ff88"), Color(hex: "00d4ff")], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color(hex: "00d4ff"), Color(hex: "7b2cbf")], startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 40, height: 40)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(MealType.allCases) { mealType in
                        if let meal = dayLog.meals[mealType], meal.hasProteinEntry {
                            HStack {
                                Image(systemName: mealType.icon)
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 24)
                                Text(mealType.rawValue)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(Int(meal.totalProtein))g")
                                    .foregroundColor(Color(hex: "00d4ff"))
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .liquidGlass(cornerRadius: 16, opacity: 0.15)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var viewModel: HabitTrackerViewModel
    @State private var goalText: String = ""
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Daily Goal Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Protein Goal")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                GlassTextField(placeholder: "Enter goal", text: $goalText, keyboardType: .decimalPad)
                                
                                Text("g")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            LiquidButton(title: "Update Goal", icon: "checkmark") {
                                updateGoal()
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 16, opacity: 0.15)
                        
                        // Quick Goals
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Goals")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach([80, 100, 120, 150], id: \.self) { goal in
                                    Button(action: { 
                                        goalText = String(goal)
                                        updateGoal()
                                    }) {
                                        Text("\(goal)g")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(.ultraThinMaterial.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 16, opacity: 0.15)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                Text("Total Logs")
                                Spacer()
                                Text("\(viewModel.history.count)")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 16, opacity: 0.15)
                        
                        // Reset Button
                        LiquidButton(title: "Reset Today's Data", icon: "arrow.counterclockwise", isDestructive: true) {
                            showingResetAlert = true
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                goalText = String(Int(viewModel.dailyProteinGoal))
            }
            .alert("Reset Today's Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetToday()
                }
            } message: {
                Text("This will clear all today's meal entries. This action cannot be undone.")
            }
        }
    }
    
    private func updateGoal() {
        if let newGoal = Double(goalText), newGoal > 0 {
            viewModel.updateGoal(newGoal)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(HabitTrackerViewModel())
}
