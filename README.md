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

## Release Strategy (Monorepo)

- CLI (`apps/cli`) continues to publish to npm using the existing local flow (`bun run --filter multicodex release`).
- macOS app (`apps/macos`) is released via GitHub Actions on tags that match `macos-v*`.

### CLI release (npm)

- Simplest commands:
  - `bun run release:cli` (default patch)
  - `bun run release:plan` (dry run; no git/npm changes)
  - `bun run release:patch`
  - `bun run release:minor`
  - `bun run release:major`
  - `bun run release:cli -- --version 0.2.0`
- These call the CLI release helper under `apps/cli`.

### macOS release (GitHub Releases)

- Streamlined root command:
  - `bun run release:macos` (tags current CLI version)
  - `bun run release:macos -- --version 0.2.0`
- Workflow: `.github/workflows/release-macos.yml`
- Output artifact: `apps/macos/build/dist/MultiCodex.dmg` uploaded to the GitHub Release for that tag.

### Release Both (CLI + macOS)

- One command for both release tracks:
  - `bun run release` (default patch release + matching macOS tag)
  - `bun run release -- --minor`
  - `bun run release -- --version 0.2.0 --no-push`
  - `bun run release -- --version 0.2.0 --no-publish`
- `--no-push` is handled by the root helper for the macOS tag push.
- To pass CLI flags that clash with root flags, use passthrough after `--`:
  - `bun run release -- --no-push -- --no-push`

## Adding workspaces later

Create a new folder under `apps/` with its own `package.json`. It will be included automatically by the root `workspaces` configuration.
