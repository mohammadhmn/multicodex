# multicodex monorepo

This repository is configured as a Bun workspace monorepo with Turborepo.

## Apps

- `apps/cli`: `multicodex` CLI app workspace.
- `apps/macos`: Native Swift macOS menu bar app workspace.

## Development

- Install dependencies: `bun install`
- Run the full quality gate: `bun run check`
- Run tests across workspaces: `bun run test`
- Typecheck across workspaces: `bun run typecheck`
- Build across workspaces: `bun run build`
- Run the macOS app: `bun run macos:dev`
- Build macOS DMG: `bun run macos:dmg`
- Run macOS checks: `bun run macos:ci`
- For advanced app-only commands, use `apps/macos/justfile` directly.

## Release Strategy

CLI and macOS now have separate release flows.

### CLI release (npm)

Use the same CLI release flow from before the monorepo split:

- `bun run release` (default patch)
- `bun run release:cli`
- `bun run release:plan` (dry run; no git/npm changes)
- `bun run release:patch`
- `bun run release:minor`
- `bun run release:major`
- `bun run release:cli -- --version 0.2.0`

These call `apps/cli/scripts/release.ts`.

### macOS release (GitHub Releases)

Create a macOS tag and let GitHub Actions build/upload the DMG:

- From root: `bun run release:macos` (patch bump)
- From app dir: `cd apps/macos && just kickoff-release`
- Explicit tag: `cd apps/macos && just release macos-v0.1.0`
- Explicit bump: `cd apps/macos && just release minor`

Workflow: `.github/workflows/release-macos.yml`  
Tag format: `macos-vMAJOR.MINOR.PATCH`  
Artifact: `apps/macos/build/dist/MultiCodex.dmg`

The macOS build always rebuilds and bundles the CLI from `apps/cli` for the tagged commit.

## Adding workspaces later

Create a new folder under `apps/` with its own `package.json`. It will be included automatically by the root `workspaces` configuration.
