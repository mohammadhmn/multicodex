# multicodex monorepo

This repository is configured as a Bun workspace monorepo with Turborepo.

## Apps

- `apps/cli`: `multicodex` CLI app workspace.
- `apps/macos`: Native Swift macOS menu bar app workspace.

## Development

- Install dependencies: `bun install`
- Run tests across workspaces: `bun run test`
- Typecheck across workspaces: `bun run typecheck`
- Build across workspaces: `bun run build`
- Run the macOS app only: `bun run --filter macos dev`
- App-focused workflow commands: `cd apps/macos && just list`

## Adding workspaces later

Create a new folder under `apps/` with its own `package.json`. It will be included automatically by the root `workspaces` configuration.
