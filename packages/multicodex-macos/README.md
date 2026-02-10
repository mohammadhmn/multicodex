# MultiCodexMenu (macOS Menu Bar App)

Native macOS SwiftUI menu bar app for `multicodex`.

## Features

- Menu bar item showing current profile.
- Lists all configured profiles from `multicodex accounts list --json`.
- Shows per-profile usage from `multicodex limits --json` (5h, weekly, credits, source).
- One-click profile switch via `multicodex accounts use <name> --json`.
- Auto refresh every 60 seconds plus manual refresh buttons.
- Card-style profile panels with progress bars and pace status (`ahead`, `on track`, `behind`).
- Reset time display toggle (`relative` / `absolute`), inspired by OpenUsage.
- Quick profile switch strip in the menu, inspired by CodexBar.
- Compact dual-bar tray glyph in the menu bar status item for at-a-glance usage.

## Build and run

Requirements:

- macOS 13+
- Xcode 15+ (or Swift 5.9+ toolchain)
- Node.js available on the machine (the app runs bundled `multicodex` via `node`)

From repo root:

```bash
cd packages/multicodex-macos
swift build
swift run MultiCodexMenu
```

With Bun workspaces / Turborepo:

```bash
bun run build
bun run --filter @multicodex/macos-app dev
```

## Command resolution

The app bundles the CLI JS (`multicodex-cli.js`) and resolves Node in this order:

1. Custom Node path set in app settings.
2. `MULTICODEX_NODE` environment variable.
3. `NODE_BINARY` environment variable.
4. Common install paths (`/opt/homebrew/bin/node`, `/usr/local/bin/node`, `/usr/bin/node`).
5. `node` from `PATH`.

If lookup fails, use `Choose Node…` from the menu.
