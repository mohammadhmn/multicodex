import SwiftUI

struct MenuBarStatusLabelView: View {
    let title: String
    let symbolName: String
    let fiveHourFraction: Double
    let weeklyFraction: Double
    let hasError: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(hasError ? .orange : .primary)

            TrayUsageBarsView(
                fiveHourFraction: fiveHourFraction,
                weeklyFraction: weeklyFraction,
                hasError: hasError
            )

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .accessibilityLabel(title)
    }
}

private struct TrayUsageBarsView: View {
    let fiveHourFraction: Double
    let weeklyFraction: Double
    let hasError: Bool

    var body: some View {
        HStack(spacing: 2) {
            usageBar(fraction: weeklyFraction, color: .blue)
            usageBar(fraction: fiveHourFraction, color: hasError ? .orange : .mint)
        }
        .frame(width: 10, height: 10)
    }

    private func usageBar(fraction: Double, color: Color) -> some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
            Capsule()
                .fill(color)
                .frame(height: max(2, 10 * min(1, max(0, fraction))))
        }
        .frame(width: 4, height: 10)
    }
}
