import SwiftUI

struct MenuBarStatusLabelView: View {
    let title: String
    let symbolName: String
    let fiveHourFraction: Double
    let weeklyFraction: Double
    let hasError: Bool

    var body: some View {
        TrayMinimalStatusIconView(
            symbolName: symbolName,
            fiveHourFraction: fiveHourFraction,
            weeklyFraction: weeklyFraction,
            hasError: hasError
        )
        .accessibilityLabel(title)
    }
}

private struct TrayMinimalStatusIconView: View {
    let symbolName: String
    let fiveHourFraction: Double
    let weeklyFraction: Double
    let hasError: Bool

    private var tint: Color {
        hasError ? .orange : .blue
    }

    private var severityFraction: Double {
        max(fiveHourFraction, weeklyFraction)
    }

    private var ringColor: Color {
        if hasError {
            return .orange
        }
        if severityFraction >= 0.95 {
            return .red
        }
        if severityFraction >= 0.8 {
            return .orange
        }
        return .secondary
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.08))
            Circle()
                .stroke(ringColor.opacity(0.9), lineWidth: 1.2)
            Image(systemName: symbolName)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 15, height: 15)
    }
}
