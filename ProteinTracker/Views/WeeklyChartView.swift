import SwiftUI
import Charts

struct WeeklyChartView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 7 Days")
                .font(.headline)
                .padding(.horizontal)
            
            let weeklyData = viewModel.weeklyTotals()
            
            Chart(weeklyData, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Protein", item.total)
                )
                .foregroundStyle(item.total >= viewModel.dailyGoal ? Color.green : Color.blue)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .padding(.horizontal)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(weeklyData.map { $0.total }.reduce(0, +) / Double(weeklyData.count)))g")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Best Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(weeklyData.map { $0.total }.max() ?? 0))g")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            Text("Daily Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(weeklyData.reversed(), id: \.date) { item in
                    DailyRow(
                        date: item.date,
                        total: item.total,
                        goal: viewModel.dailyGoal
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct DailyRow: View {
    let date: Date
    let total: Double
    let goal: Double
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }
    
    private var isGoalMet: Bool {
        total >= goal
    }
    
    var body: some View {
        HStack {
            Text(dateFormatter.string(from: date))
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 4) {
                if isGoalMet {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Text("\(Int(total))g")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isGoalMet ? .green : .primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
