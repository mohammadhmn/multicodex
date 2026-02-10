import SwiftUI

struct ProfileUsageCardView: View {
    let profile: ProfileUsage
    let resetDisplayMode: ResetDisplayMode
    let isSwitching: Bool
    let onSwitch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            metrics
            details
            statusMessage
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(profile.isCurrent ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(profile.name)
                .font(.headline)

            if profile.isCurrent {
                Text("Current")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.18), in: Capsule())
            }

            Spacer()

            if !profile.isCurrent {
                Button {
                    onSwitch()
                } label: {
                    if isSwitching {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Switch")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isSwitching)
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            UsageMetricSummaryView(metric: profile.usage.fiveHour, resetDisplayMode: resetDisplayMode)
            UsageMetricSummaryView(metric: profile.usage.weekly, resetDisplayMode: resetDisplayMode)
            CreditsSummaryView(credits: profile.usage.credits)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Source: \(profile.source)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Last used: \(profile.lastUsedLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let status = profile.lastLoginStatusPreview {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let usageError = profile.usageError {
            Text(usageError)
                .font(.caption)
                .foregroundStyle(.red)
        } else if !profile.hasAuth {
            Text("Profile has no auth yet.")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

private struct UsageMetricSummaryView: View {
    let metric: UsageMetric
    let resetDisplayMode: ResetDisplayMode

    private var percentValue: Double {
        metric.usedPercent ?? 0
    }

    private var barColor: Color {
        if percentValue >= 95 {
            return .red
        }
        if percentValue >= 80 {
            return .orange
        }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(metric.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(metric.percentText)
                    .font(.subheadline.weight(.semibold))
            }

            ProgressView(value: metric.normalizedFraction)
                .tint(barColor)

            Text(metric.resetText(mode: resetDisplayMode))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let pace = metric.paceStatus {
                Text("Pace: \(pace.label)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(paceColor(for: pace))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paceColor(for pace: PaceStatus) -> Color {
        switch pace {
        case .ahead:
            return .green
        case .onTrack:
            return .secondary
        case .behind:
            return .orange
        }
    }
}

private struct CreditsSummaryView: View {
    let credits: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("credits")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(credits)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(width: 82, alignment: .leading)
    }
}
