import SwiftUI

struct ProfileUsageCardView: View {
    let profile: ProfileUsage
    let resetDisplayMode: ResetDisplayMode
    let isSwitching: Bool
    let onSwitch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            metricRow
            metadata
            statusLine
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(profile.isCurrent ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.headline)

                    if profile.isCurrent {
                        statusBadge(text: "Current", tint: .accentColor)
                    }

                    if !profile.hasAuth {
                        statusBadge(text: "Auth needed", tint: .orange)
                    }
                }

                Text("Last used \(profile.lastUsedLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if !profile.isCurrent {
                Button {
                    onSwitch()
                } label: {
                    if isSwitching {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 48)
                    } else {
                        Text("Switch")
                            .frame(minWidth: 48)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isSwitching)
            }
        }
    }

    private var metricRow: some View {
        HStack(spacing: 8) {
            CompactMetricTile(metric: profile.usage.fiveHour, resetDisplayMode: resetDisplayMode)
            CompactMetricTile(metric: profile.usage.weekly, resetDisplayMode: resetDisplayMode)
        }
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            Label(profile.source, systemImage: "clock.arrow.circlepath")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let status = profile.lastLoginStatusPreview {
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if let usageError = profile.usageError {
            Label(usageError, systemImage: "xmark.octagon.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func statusBadge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}

private struct CompactMetricTile: View {
    let metric: UsageMetric
    let resetDisplayMode: ResetDisplayMode

    private var tone: Color {
        let value = metric.usedPercent ?? 0
        if value >= 95 { return .red }
        if value >= 80 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(metric.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(metric.percentText)
                    .font(.subheadline.weight(.bold))
            }

            ProgressView(value: metric.normalizedFraction)
                .tint(tone)

            Text(metric.resetText(mode: resetDisplayMode))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let pace = metric.paceStatus {
                Text(pace.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tone)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
