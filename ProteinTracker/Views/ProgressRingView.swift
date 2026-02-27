import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let current: Double
    let goal: Double
    
    private var ringColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .blue
        } else {
            return .orange
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.1)
                .foregroundColor(ringColor)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    ringColor.gradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            VStack(spacing: 8) {
                Text("\(Int(current))g")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                
                Text("of \(Int(goal))g goal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if progress >= 1.0 {
                    Label("Goal reached!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("\(Int(goal - current))g remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
