import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.15
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, opacity: Double = 0.15) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    
    init(cornerRadius: CGFloat = 20, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .liquidGlass(cornerRadius: cornerRadius)
    }
}

// MARK: - Gradient Background
struct LiquidBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "1a1a2e"),
                Color(hex: "16213e"),
                Color(hex: "0f3460"),
                Color(hex: "1a1a2e")
            ],
            startPoint: animateGradient ? .topLeading : .topTrailing,
            endPoint: animateGradient ? .bottomTrailing : .bottomLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Progress Ring with Liquid Effect
struct LiquidProgressRing: View {
    let progress: Double
    let current: Double
    let goal: Double
    var lineWidth: CGFloat = 20
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "00d4ff"),
                            Color(hex: "7b2cbf"),
                            Color(hex: "ff006e")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(hex: "00d4ff").opacity(0.5), radius: 10)
            
            // Center content
            VStack(spacing: 4) {
                Text("\(Int(current))g")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("of \(Int(goal))g")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                if progress >= 1.0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Goal Met!")
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "00ff88"))
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Meal Card with Liquid Glass
struct MealCard: View {
    let mealType: MealType
    let mealEntry: MealEntry
    let onAddItem: () -> Void
    let onRemoveItem: (Int) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }}) {
                HStack {
                    Image(systemName: mealType.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "00d4ff"), Color(hex: "7b2cbf")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mealType.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(mealType.timeRange)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Protein badge
                    if mealEntry.hasProteinEntry {
                        Text("\(Int(mealEntry.totalProtein))g")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "00d4ff").opacity(0.6), Color(hex: "7b2cbf").opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            mealEntry.hasProteinEntry 
                                ? LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.orange.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1
                        )
                )
            }
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 8) {
                    if mealEntry.items.isEmpty {
                        Text("No items added")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(mealEntry.items.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                Text(item.name)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(item.protein))g")
                                    .foregroundColor(Color(hex: "00d4ff"))
                                Button(action: { onRemoveItem(index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Button(action: onAddItem) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Food Item")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "00d4ff").opacity(0.3), Color(hex: "7b2cbf").opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Input Field with Glass Effect
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

// MARK: - Button with Liquid Gradient
struct LiquidButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isDestructive 
                            ? LinearGradient(colors: [.red.opacity(0.6), .red.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(hex: "00d4ff"), Color(hex: "7b2cbf")], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: (isDestructive ? .red : Color(hex: "00d4ff")).opacity(0.3), radius: 10)
            )
        }
    }
}
