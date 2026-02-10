# multicodex monorepo

This repository is configured as a Bun workspace monorepo with Turborepo.

## Packages

- `packages/multicodex`: `multicodex` CLI package.

## Development

- Install dependencies: `bun install`
- Run tests across workspaces: `bun run test`
- Typecheck across workspaces: `bun run typecheck`
- Build across workspaces: `bun run build`

## Adding packages later

Create a new folder under `packages/` with its own `package.json`. It will be included automatically by the root `workspaces` configuration.
