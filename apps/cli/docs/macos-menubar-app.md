# macOS menu bar app (native Swift)

This repo includes a native macOS menu bar app at:

- `apps/macos`

It provides:

- Profile list from `multicodex accounts list --json`
- Usage for all profiles from `multicodex limits --json`
- One-click switching with `multicodex accounts use <name> --json`
- Settings UI for account/login management:
  - add, rename, remove profiles
  - import current auth into a profile
  - run login status check for a profile
  - launch Terminal login flow for a selected profile

## Build

```bash
cd apps/macos
swift build
```

## Run

```bash
cd apps/macos
swift run MultiCodexMenu
```

## Notes

- Requires macOS 13+.
- The app auto-refreshes every 5 minutes (matching the limits cache TTL).
- The app bundles the `multicodex` CLI JS and runs it via Node.
- If Node is not auto-detected, use `Choose Node…` from the menu to point to your Node executable.
- Local app workflow is available via `apps/macos/justfile` (`just doctor`, `just dev`, `just dmg`, `just ci`, etc).
