import AppKit
import SwiftUI

struct UsageMenuContentView: View {
    @ObservedObject var viewModel: UsageMenuViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let error = viewModel.lastRefreshError {
                errorBanner(error)
            }

            quickSwitchStrip
            profilesContent
            footer
        }
        .padding(14)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MultiCodex")
                        .font(.headline)
                    Text(viewModel.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.isRefreshing)

                    Button {
                        viewModel.refreshLive()
                    } label: {
                        Label("Refresh Live", systemImage: "bolt.horizontal")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(viewModel.isRefreshing)
                }
            }

            HStack {
                Text(viewModel.lastUpdatedLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if viewModel.isRefreshing {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
    }

    private var quickSwitchStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.profiles) { profile in
                    Button {
                        viewModel.switchToProfile(named: profile.name)
                    } label: {
                        HStack(spacing: 5) {
                            Text(profile.name)
                            if profile.isCurrent {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                            }
                        }
                    }
                    .buttonStyle(QuickProfileButtonStyle(isCurrent: profile.isCurrent))
                    .disabled(viewModel.switchingProfileName != nil || profile.isCurrent)
                }
            }
        }
    }

    @ViewBuilder
    private var profilesContent: some View {
        if viewModel.profiles.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("No profiles found")
                    .font(.subheadline.weight(.semibold))
                Text("Run multicodex login to add an account, then refresh.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.profiles) { profile in
                        ProfileUsageCardView(
                            profile: profile,
                            resetDisplayMode: viewModel.resetDisplayMode,
                            isSwitching: viewModel.switchingProfileName == profile.name,
                            onSwitch: { viewModel.switchToProfile(named: profile.name) }
                        )
                    }
                }
            }
            .frame(minHeight: 240, maxHeight: 420)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(viewModel.resetDisplayMode.buttonLabel) {
                    viewModel.toggleResetDisplayMode()
                }
                .buttonStyle(.plain)
                .font(.caption)

                Spacer()

                Button("Config") {
                    viewModel.openMulticodexConfigDirectory()
                }
                .buttonStyle(.plain)
                .font(.caption)

                Button("Settings") {
                    openSettingsWindow()
                }
                .buttonStyle(.plain)
                .font(.caption)
            }

            if let hint = viewModel.cliResolutionHint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func openSettingsWindow() {
        if !NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) {
            _ = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct QuickProfileButtonStyle: ButtonStyle {
    let isCurrent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isCurrent ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(configuration.isPressed ? 0.2 : 0.12))
            )
            .foregroundStyle(isCurrent ? Color.accentColor : Color.primary)
    }
}
