import SwiftUI

struct SettingsContentView: View {
    @ObservedObject var viewModel: UsageMenuViewModel
    @State private var nodePathDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MultiCodex Menu Settings")
                .font(.title3.weight(.semibold))

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

            Spacer(minLength: 0)
        }
        .onAppear {
            nodePathDraft = viewModel.customNodePath
        }
        .onChange(of: viewModel.customNodePath) { nodePathDraft = $0 }
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
