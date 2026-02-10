import SwiftUI

@main
struct MultiCodexMenuApp: App {
    @StateObject private var viewModel = UsageMenuViewModel()

    var body: some Scene {
        MenuBarExtra {
            UsageMenuContentView(viewModel: viewModel)
                .frame(minWidth: 460, idealWidth: 500)
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
