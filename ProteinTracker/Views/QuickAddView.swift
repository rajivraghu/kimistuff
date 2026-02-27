import SwiftUI

struct QuickAddView: View {
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    let quickAmounts = [10, 20, 25, 30, 50]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        QuickAddButton(amount: amount) {
                            viewModel.addEntry(
                                amount: Double(amount),
                                source: "Quick Add",
                                notes: nil
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct QuickAddButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("+\(amount)g")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(width: 80, height: 70)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
    }
}
