import SwiftUI

struct AddEntryView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: ProteinTrackerViewModel
    
    @State private var amount: String = ""
    @State private var source: String = ""
    @State private var notes: String = ""
    @State private var selectedPreset: String? = nil
    
    let presets = ["Chicken", "Eggs", "Whey Protein", "Fish", "Beef", "Tofu", "Greek Yogurt"]
    
    var isValid: Bool {
        Double(amount) != nil && Double(amount)! > 0 && !source.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        Text("grams")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Source")) {
                    TextField("e.g., Chicken breast, Whey protein", text: $source)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                PresetButton(
                                    title: preset,
                                    isSelected: selectedPreset == preset
                                ) {
                                    selectedPreset = preset
                                    source = preset
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("e.g., Post-workout, Lunch", text: $notes)
                }
                
                Section {
                    Button(action: saveEntry) {
                        HStack {
                            Spacer()
                            Text("Add Entry")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Add Protein")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        viewModel.addEntry(
            amount: amountValue,
            source: source,
            notes: notes.isEmpty ? nil : notes
        )
        
        isPresented = false
    }
}

struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}
