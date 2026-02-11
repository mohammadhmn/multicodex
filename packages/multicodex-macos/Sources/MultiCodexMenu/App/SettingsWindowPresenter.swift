import AppKit
import SwiftUI

@MainActor
final class SettingsWindowPresenter {
    static let shared = SettingsWindowPresenter()

    private var window: NSWindow?

    private init() {}

    func show(viewModel: UsageMenuViewModel) {
        NSApp.setActivationPolicy(.regular)

        if let window {
            if let hosting = window.contentViewController as? NSHostingController<SettingsContentView> {
                hosting.rootView = SettingsContentView(viewModel: viewModel)
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = SettingsContentView(viewModel: viewModel)
            .padding(16)
            .frame(minWidth: 680, minHeight: 760)

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "MultiCodex Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("MultiCodexSettingsWindow")

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
