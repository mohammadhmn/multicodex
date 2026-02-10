import AppKit
import SwiftUI

@main
struct MultiCodexMenuApp: App {
    @StateObject private var viewModel = UsageMenuViewModel()

    var body: some Scene {
        MenuBarExtra {
            UsageMenuContentView(viewModel: viewModel)
                .frame(minWidth: 420)
                .onAppear {
                    viewModel.start()
                }
        } label: {
            MenuBarStatusLabelView(
                title: viewModel.menuBarTitle,
                symbolName: viewModel.menuBarSymbol,
                fiveHourFraction: viewModel.currentFiveHourFraction,
                weeklyFraction: viewModel.currentWeeklyFraction,
                hasError: viewModel.lastRefreshError != nil
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsContentView(viewModel: viewModel)
                .padding(16)
                .frame(width: 640)
        }
    }
}

struct MenuBarStatusLabelView: View {
    let title: String
    let symbolName: String
    let fiveHourFraction: Double
    let weeklyFraction: Double
    let hasError: Bool

    var body: some View {
        HStack(spacing: 5) {
            if hasError {
                Image(systemName: symbolName)
                    .font(.system(size: 11))
            } else {
                MiniUsageGlyphView(
                    firstFraction: fiveHourFraction,
                    secondFraction: weeklyFraction
                )
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
    }
}

struct MiniUsageGlyphView: View {
    let firstFraction: Double
    let secondFraction: Double

    var body: some View {
        VStack(spacing: 2) {
            MiniUsageBar(fraction: firstFraction)
            MiniUsageBar(fraction: secondFraction)
        }
    }
}

struct MiniUsageBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(1, max(0, fraction))
            let width = proxy.size.width * clamped
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.25))
                Capsule()
                    .fill(Color.primary)
                    .frame(width: clamped == 0 ? 0 : width)
            }
        }
        .frame(width: 12, height: 2.6)
    }
}

struct UsageMenuContentView: View {
    @ObservedObject var viewModel: UsageMenuViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection

            if let error = viewModel.lastRefreshError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.profiles.isEmpty {
                Text("No profiles found. Create one with `multicodex accounts add <name>`.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProfileSwitcherStripView(
                    profiles: viewModel.profiles,
                    switchingProfileName: viewModel.switchingProfileName,
                    onSwitch: { viewModel.switchToProfile(named: $0) }
                )

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.profiles) { profile in
                            ProfileUsageCardView(
                                profile: profile,
                                resetDisplayMode: viewModel.resetDisplayMode,
                                switchingProfileName: viewModel.switchingProfileName,
                                onSwitch: { viewModel.switchToProfile(named: profile.name) }
                            )
                        }
                    }
                }
                .frame(maxHeight: 420)
            }

            Divider()

            controlRow

            if !viewModel.customNodePath.isEmpty {
                Text("Custom Node: \(viewModel.customNodePath)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let resolutionHint = viewModel.cliResolutionHint {
                Text(resolutionHint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MultiCodex")
                    .font(.headline)
                Text(viewModel.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 8) {
            Button("Refresh") {
                viewModel.refresh(userInitiated: true, bypassCache: false)
            }

            Button("Refresh Live") {
                viewModel.refresh(userInitiated: true, bypassCache: true)
            }

            Button(viewModel.resetDisplayMode.buttonLabel) {
                viewModel.toggleResetDisplayMode()
            }

            Spacer()

            Text(viewModel.lastUpdatedLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu("More") {
                Button("Choose Node…") {
                    viewModel.chooseCustomNodePath()
                }

                Button("Use Auto Node Detection") {
                    viewModel.clearCustomNodePath()
                }
                .disabled(viewModel.customNodePath.isEmpty)

                Divider()

                Button("Open Multicodex Config") {
                    viewModel.openMulticodexConfigDirectory()
                }

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

struct ProfileSwitcherStripView: View {
    let profiles: [ProfileUsage]
    let switchingProfileName: String?
    let onSwitch: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(profiles) { profile in
                    Button {
                        onSwitch(profile.name)
                    } label: {
                        HStack(spacing: 6) {
                            if profile.isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }

                            Text(profile.name)
                                .font(.caption)

                            if let percent = profile.primaryPercentText {
                                Text(percent)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(profile.isCurrent ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(profile.isCurrent || switchingProfileName != nil)
                }
            }
        }
    }
}

struct ProfileUsageCardView: View {
    let profile: ProfileUsage
    let resetDisplayMode: ResetDisplayMode
    let switchingProfileName: String?
    let onSwitch: () -> Void

    private var switchLabel: String {
        if switchingProfileName == profile.name {
            return "Switching..."
        }
        if profile.isCurrent {
            return "Current"
        }
        return "Switch"
    }

    private var canSwitch: Bool {
        !profile.isCurrent && switchingProfileName == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(profile.name)
                    .font(.headline)

                if profile.isCurrent {
                    Text("current")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }

                Spacer()

                Button(switchLabel, action: onSwitch)
                    .disabled(!canSwitch)
            }

            MetricProgressSectionView(
                title: "Session (5h)",
                metric: profile.usage.fiveHour,
                resetDisplayMode: resetDisplayMode
            )

            MetricProgressSectionView(
                title: "Weekly",
                metric: profile.usage.weekly,
                resetDisplayMode: resetDisplayMode
            )

            HStack(spacing: 10) {
                Text("Credits: \(profile.usage.credits)")
                    .font(.caption2)
                Text("Source: \(profile.source)")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            Text("Auth: \(profile.hasAuth ? "saved" : "missing")  |  Last used: \(profile.lastUsedLabel)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let status = profile.lastLoginStatusPreview {
                Text("Status: \(status)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let usageError = profile.usageError {
                Text(usageError)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

struct MetricProgressSectionView: View {
    let title: String
    let metric: UsageMetric
    let resetDisplayMode: ResetDisplayMode

    private var tint: Color {
        guard let percent = metric.usedPercent else {
            return .secondary
        }

        if percent >= 95 {
            return .red
        }
        if percent >= 80 {
            return .orange
        }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if let paceStatus = metric.paceStatus {
                    PaceStatusBadgeView(status: paceStatus)
                }

                Text(metric.percentText)
                    .font(.caption)
                    .monospacedDigit()
            }

            UsageProgressBarView(fraction: metric.normalizedFraction, tint: tint)

            Text(metric.resetText(mode: resetDisplayMode))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct PaceStatusBadgeView: View {
    let status: PaceStatus

    private var dotColor: Color {
        switch status {
        case .ahead:
            return .green
        case .onTrack:
            return .yellow
        case .behind:
            return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Text(status.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct UsageProgressBarView: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(1, max(0, fraction))
            let fillWidth = max(2, proxy.size.width * clamped)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))

                Capsule()
                    .fill(tint)
                    .frame(width: clamped == 0 ? 0 : fillWidth)
            }
        }
        .frame(height: 6)
    }
}

struct SettingsContentView: View {
    @ObservedObject var viewModel: UsageMenuViewModel
    @State private var draftPath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Multicodex Menu Settings")
                .font(.title3)

            Text("The app runs bundled `multicodex` via Node. Set a custom Node executable path if auto-detection fails.")
            .font(.caption)
            .foregroundStyle(.secondary)

            TextField("/opt/homebrew/bin/node", text: $draftPath)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Choose…") {
                    viewModel.chooseCustomNodePath()
                }

                Button("Save") {
                    viewModel.updateCustomNodePath(draftPath)
                }

                Button("Reset") {
                    draftPath = ""
                    viewModel.clearCustomNodePath()
                }

                Spacer()

                Button(viewModel.resetDisplayMode.buttonLabel) {
                    viewModel.toggleResetDisplayMode()
                }
            }

            if let resolutionHint = viewModel.cliResolutionHint {
                Text(resolutionHint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .onAppear {
            draftPath = viewModel.customNodePath
        }
        .onChange(of: viewModel.customNodePath) { newValue in
            draftPath = newValue
        }
    }
}
