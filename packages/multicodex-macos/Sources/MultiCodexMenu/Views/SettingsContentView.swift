import SwiftUI

struct SettingsContentView: View {
    @ObservedObject var viewModel: UsageMenuViewModel
    @State private var nodePathDraft = ""
    @State private var newProfileName = ""
    @State private var renameDrafts: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("MultiCodex Menu Settings")
                    .font(.title3.weight(.semibold))

                profilesAndLoginGroup
                nodeRuntimeGroup
                usageDisplayGroup
                dataGroup
                diagnosticsGroup
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            nodePathDraft = viewModel.customNodePath
            syncRenameDrafts()
        }
        .onChange(of: viewModel.customNodePath) { nodePathDraft = $0 }
        .onChange(of: viewModel.profiles.map(\.name)) { _ in
            syncRenameDrafts()
        }
    }

    private var profilesAndLoginGroup: some View {
        GroupBox("Profiles & Login") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("new-profile", text: $newProfileName)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        viewModel.addProfile(named: newProfileName)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProfileActionRunning)
                }

                if let message = viewModel.profileActionMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if let error = viewModel.profileActionError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if viewModel.profiles.isEmpty {
                    Text("No profiles configured.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.profiles) { profile in
                            profileManagementRow(profile)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func profileManagementRow(_ profile: ProfileUsage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(profile.name)
                    .font(.subheadline.weight(.semibold))

                if profile.isCurrent {
                    Text("Current")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }

                if !profile.hasAuth {
                    Text("No auth")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                }

                Spacer(minLength: 8)

                if viewModel.profileActionInFlightName == profile.name {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack(spacing: 8) {
                if !profile.isCurrent {
                    Button("Use") {
                        viewModel.switchToProfile(named: profile.name)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProfileActionRunning)
                }

                Button("Login…") {
                    viewModel.openLoginInTerminal(for: profile.name)
                }
                .buttonStyle(.bordered)
                .disabled(isProfileActionRunning)

                Button("Status") {
                    viewModel.checkLoginStatus(for: profile.name)
                }
                .buttonStyle(.bordered)
                .disabled(isProfileActionRunning)

                Menu("More") {
                    Button("Import current auth") {
                        viewModel.importCurrentAuth(into: profile.name)
                    }

                    Divider()

                    Button("Remove profile", role: .destructive) {
                        viewModel.removeProfile(named: profile.name, deleteData: false)
                    }

                    Button("Remove + delete data", role: .destructive) {
                        viewModel.removeProfile(named: profile.name, deleteData: true)
                    }
                }
                .disabled(isProfileActionRunning)
            }

            HStack(spacing: 8) {
                TextField("rename", text: renameBinding(for: profile.name))
                    .textFieldStyle(.roundedBorder)

                Button("Rename") {
                    viewModel.renameProfile(from: profile.name, to: renameDrafts[profile.name] ?? profile.name)
                }
                .buttonStyle(.bordered)
                .disabled(cannotRename(profile.name) || isProfileActionRunning)
            }

            if let status = profile.lastLoginStatusPreview {
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var nodeRuntimeGroup: some View {
        GroupBox("Node runtime") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("/opt/homebrew/bin/node", text: $nodePathDraft)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save") {
                        viewModel.updateCustomNodePath(nodePathDraft)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(normalized(nodePathDraft) == viewModel.customNodePath)

                    Button("Choose Node…") {
                        viewModel.chooseCustomNodePath()
                    }
                    .buttonStyle(.bordered)

                    Button("Use Auto") {
                        nodePathDraft = ""
                        viewModel.clearCustomNodePath()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.customNodePath.isEmpty)
                }

                Text("Leave empty to auto-detect Node from env vars, standard install paths, or PATH.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var usageDisplayGroup: some View {
        GroupBox("Usage display") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reset labels")
                    .font(.subheadline.weight(.semibold))
                Button(viewModel.resetDisplayMode.buttonLabel) {
                    viewModel.toggleResetDisplayMode()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dataGroup: some View {
        GroupBox("Data") {
            HStack {
                Button("Refresh") {
                    viewModel.refresh()
                }
                .buttonStyle(.bordered)

                Button("Refresh Live") {
                    viewModel.refreshLive()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var diagnosticsGroup: some View {
        GroupBox("Diagnostics") {
            VStack(alignment: .leading, spacing: 8) {
                if let hint = viewModel.cliResolutionHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                } else {
                    Text("Run a refresh to see command resolution details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Open multicodex config directory") {
                    viewModel.openMulticodexConfigDirectory()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var isProfileActionRunning: Bool {
        viewModel.profileActionInFlightName != nil || viewModel.switchingProfileName != nil
    }

    private func renameBinding(for profileName: String) -> Binding<String> {
        Binding(
            get: { renameDrafts[profileName] ?? profileName },
            set: { renameDrafts[profileName] = $0 }
        )
    }

    private func cannotRename(_ profileName: String) -> Bool {
        let raw = renameDrafts[profileName] ?? profileName
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == profileName
    }

    private func syncRenameDrafts() {
        let names = Set(viewModel.profiles.map(\.name))
        renameDrafts = renameDrafts.filter { names.contains($0.key) }
        for profile in viewModel.profiles where renameDrafts[profile.name] == nil {
            renameDrafts[profile.name] = profile.name
        }
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
