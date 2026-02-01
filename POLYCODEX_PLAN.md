# polycodex — Auth-only multi-account wrapper for Codex CLI (Bun + TypeScript)

Goal: support multiple Codex “accounts” (logins) and quick switching **without forking or patching Codex**.

Design constraint (as requested): **polycodex only manages authentication** and reuses the default Codex home (`~/.codex`) for everything else (rules, skills, config, sessions, history, etc).

## How Codex stores auth

- Codex persists authentication state in `~/.codex/auth.json` (by default).
- Codex persists non-auth state (history, sessions, rules, skills, etc) in the same `~/.codex` directory.

Because Codex does not expose separate paths for “auth vs everything else”, `polycodex` implements account switching by swapping `~/.codex/auth.json`.

## Core approach

### Per-account auth snapshots

`polycodex` stores one auth snapshot per account:

- `~/.config/polycodex/accounts/<name>/auth.json`

These files are treated as opaque Codex-owned state; `polycodex` does not parse or modify token contents.

### Switching accounts

To run Codex as a given account, `polycodex`:

1) Acquires an exclusive lock: `~/.config/polycodex/locks/auth.lockdir`
2) Replaces `~/.codex/auth.json` with the account’s snapshot (or deletes it if the account has no snapshot yet)
3) Runs `codex ...` normally (no `CODEX_HOME` override)
4) After `codex` exits, snapshots the resulting `~/.codex/auth.json` back into the account’s snapshot file (to keep refreshes)
5) Releases the lock

Optional: `--restore` restores the previous `~/.codex/auth.json` after the run (useful for one-off commands).

## CLI surface

### Profiles

- `polycodex profile add <name>`
- `polycodex profile list`
- `polycodex profile use <name>` (sets default account and applies its auth to `~/.codex/auth.json`)
- `polycodex profile current`
- `polycodex profile rm <name> [--delete-data]`

### Auth utilities

- `polycodex auth import [--account <name>]`
  - Copies current `~/.codex/auth.json` into the selected account’s snapshot (read-only from `~/.codex`, no changes).
- `polycodex auth apply <name> [--force]`
  - Writes the account snapshot into `~/.codex/auth.json` (switches account for plain `codex` usage).

### Running codex

- `polycodex` (launch interactive `codex` as current account)
- `polycodex run [--account <name>] [--force] [--restore] -- <codex args...>`
- `polycodex login/logout/status ...` (runs the corresponding `codex` subcommands under the selected account)
- Passthrough: `polycodex <codex args...>` runs `codex` using the current account

## Concurrency + safety

- Only `~/.codex/auth.json` is modified; everything else in `~/.codex` is untouched by polycodex.
- A lock prevents concurrent sessions from swapping auth mid-run.
- `--force` can reclaim a stale lock (e.g. a previous run crashed).
