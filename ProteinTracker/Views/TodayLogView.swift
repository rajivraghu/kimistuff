import SwiftUI

struct TodayLogView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Log")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.todaysEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if viewModel.todaysEntries.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.todaysEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                        EntryRow(entry: entry)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct EntryRow: View {
    let entry: ProteinEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.source)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(entry.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(entry.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No entries yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Tap + to add your first protein entry")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
    }
}
