import fs from "node:fs/promises";
import { spawnSync } from "node:child_process";

import { loadConfig, resolveAccountName } from "./config";
import {
  addAccount,
  currentAccount,
  listAccounts,
  removeAccount,
  renameAccount,
  useAccount,
} from "./profiles";
import { applyAccountAuthToDefault, importDefaultAuthToAccount } from "./authSwap";
import { runCodex, runCodexCapture } from "./runCodex";
import { accountAuthPath } from "./paths";
import { readAccountMeta, updateAccountMeta } from "./accountMeta";

function printHelp(): void {
  console.log(`polycodex - manage multiple Codex accounts (OAuth)

Usage:
  polycodex accounts list
  polycodex accounts add <name>
  polycodex accounts remove <name> [--delete-data]
  polycodex accounts rename <old> <new>
  polycodex accounts use <name>
  polycodex accounts current
  polycodex accounts import [<name>]

Aliases:
  polycodex accounts            (list)
  polycodex ls                  (accounts list)
  polycodex add <name>          (accounts add)
  polycodex rm <name>           (accounts remove)
  polycodex rename <old> <new>  (accounts rename)
  polycodex use <name>          (accounts use)
  polycodex switch <name>       (accounts use)
  polycodex current             (accounts current)
  polycodex which               (accounts current)
  polycodex import [<name>]     (accounts import)

Run Codex:
  polycodex                     (launch codex with current account)
  polycodex run [<name>] [--temp] [--force] -- <codex args...>
  polycodex <codex args...>     (passthrough using current account)

Status:
  polycodex status [<name>]
  polycodex whoami              (alias)

Quota (best-effort):
  polycodex quota [<name>]
  polycodex quota open [<name>]
  polycodex quota set [<name>] <note...>
  polycodex quota clear [<name>]

Notes:
  - polycodex swaps ~/.codex/auth.json under a lock; everything else stays in ~/.codex.
  - Quota (weekly/sessions) is not exposed via a stable public API; polycodex stores notes and can open the UI.
`);
}

function die(message: string, exitCode = 1): never {
  console.error(message);
  process.exit(exitCode);
}

function popFlag(args: string[], flag: string): boolean {
  const idx = args.indexOf(flag);
  if (idx === -1) return false;
  args.splice(idx, 1);
  return true;
}

function popFlagValue(args: string[], flag: string): string | undefined {
  const idx = args.indexOf(flag);
  if (idx === -1) return undefined;
  const value = args[idx + 1];
  if (!value || value.startsWith("-")) die(`Missing value for ${flag}`);
  args.splice(idx, 2);
  return value;
}

function splitAtDoubleDash(args: string[]): { before: string[]; after: string[] } {
  const idx = args.indexOf("--");
  if (idx === -1) return { before: args.slice(), after: [] };
  return { before: args.slice(0, idx), after: args.slice(idx + 1) };
}

async function fileExists(p: string): Promise<boolean> {
  try {
    await fs.stat(p);
    return true;
  } catch {
    return false;
  }
}

function openUrl(url: string): void {
  const platform = process.platform;
  if (platform === "darwin") {
    spawnSync("open", [url], { stdio: "inherit" });
    return;
  }
  if (platform === "win32") {
    spawnSync("cmd", ["/c", "start", "", url], { stdio: "inherit" });
    return;
  }
  spawnSync("xdg-open", [url], { stdio: "inherit" });
}

async function resolveExistingAccount(requested?: string): Promise<string> {
  const config = await loadConfig();
  const name = resolveAccountName(config, requested);
  if (!(name in config.accounts)) die(`Unknown account: ${name}`);
  return name;
}

async function cmdAccounts(rest: string[]): Promise<void> {
  const [actionRaw, ...tail] = rest;
  const action = actionRaw ?? "list";

  if (action === "list") {
    const { accounts } = await listAccounts();
    if (!accounts.length) {
      console.log("No accounts configured. Run: polycodex accounts add <name>");
      return;
    }

    for (const a of accounts) {
      const meta = await readAccountMeta(a.name);
      const hasAuth = await fileExists(accountAuthPath(a.name));
      const status = meta?.lastLoginStatus ? meta.lastLoginStatus : hasAuth ? "auth saved" : "no auth";
      const last = meta?.lastUsedAt ?? "never";
      const quota = meta?.quotaNote ? `  quota: ${meta.quotaNote}` : "";
      console.log(`${a.isCurrent ? "*" : " "} ${a.name}  ${status}  last used: ${last}${quota}`);
    }
    return;
  }

  if (action === "add") {
    const name = tail[0];
    if (!name) die("Missing name. Usage: polycodex accounts add <name>");
    await addAccount({ name });
    console.log(`Added account: ${name}`);
    return;
  }

  if (action === "remove") {
    const name = tail[0];
    if (!name) die("Missing name. Usage: polycodex accounts remove <name>");
    const deleteData = popFlag(tail, "--delete-data");
    await removeAccount({ name, deleteData });
    console.log(`Removed account: ${name}`);
    return;
  }

  if (action === "rename") {
    const from = tail[0];
    const to = tail[1];
    if (!from || !to) die("Usage: polycodex accounts rename <old> <new>");
    await renameAccount(from, to);
    console.log(`Renamed account: ${from} -> ${to}`);
    return;
  }

  if (action === "use") {
    const name = tail[0];
    if (!name) die("Missing name. Usage: polycodex accounts use <name>");
    await useAccount(name);
    await applyAccountAuthToDefault(name, false);
    console.log(`Now using: ${name}`);
    return;
  }

  if (action === "current") {
    const name = await currentAccount();
    if (!name) die("No current account set. Run: polycodex accounts add <name>", 2);
    console.log(name);
    return;
  }

  if (action === "import") {
    const name = tail[0];
    const account = await resolveExistingAccount(name);
    await importDefaultAuthToAccount(account);
    await updateAccountMeta(account, { lastUsedAt: new Date().toISOString() });
    console.log(`Imported ~/.codex/auth.json into account: ${account}`);
    return;
  }

  die(`Unknown accounts action: ${action}`);
}

async function runCodexWithAccount({
  account,
  codexArgs,
  forceLock,
  restorePreviousAuth,
}: {
  account?: string;
  codexArgs: string[];
  forceLock: boolean;
  restorePreviousAuth: boolean;
}): Promise<void> {
  const resolved = await resolveExistingAccount(account);
  await updateAccountMeta(resolved, { lastUsedAt: new Date().toISOString() });

  const exitCode = await runCodex({
    account: resolved,
    codexArgs,
    forceLock,
    restorePreviousAuth,
  });
  process.exit(exitCode);
}

async function cmdRun(rest: string[]): Promise<void> {
  const { before, after } = splitAtDoubleDash(rest);
  if (!rest.includes("--")) {
    die("Usage: polycodex run [<name>] [--temp] [--force] -- <codex args...>");
  }

  // Support both positional account and --account.
  const accountFlag = popFlagValue(before, "--account");
  const positional = before[0] && !before[0].startsWith("-") ? before.shift() : undefined;
  const account = accountFlag ?? positional;

  const force = popFlag(before, "--force");
  const temp = popFlag(before, "--temp") || popFlag(before, "--restore");
  if (before.length) die(`Unknown polycodex flag(s): ${before.join(" ")}`);

  await runCodexWithAccount({
    account,
    codexArgs: after,
    forceLock: force,
    restorePreviousAuth: temp,
  });
}

async function cmdStatus(rest: string[]): Promise<void> {
  const args = rest.slice();
  const accountFlag = popFlagValue(args, "--account");
  const positional = args[0] && !args[0].startsWith("-") ? args[0] : undefined;
  const account = await resolveExistingAccount(accountFlag ?? positional);

  const result = await runCodexCapture({
    account,
    codexArgs: ["login", "status"],
    forceLock: false,
    restorePreviousAuth: true,
  });

  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  const output = (result.stdout + result.stderr).trim();

  await updateAccountMeta(account, {
    lastUsedAt: new Date().toISOString(),
    lastLoginStatus: output || undefined,
    lastLoginCheckedAt: new Date().toISOString(),
  });

  process.exit(result.exitCode);
}

async function cmdQuota(rest: string[]): Promise<void> {
  const [sub, ...restTail] = rest;
  const known = new Set(["open", "set", "clear"]);
  const action = sub && known.has(sub) ? sub : "show";
  const tail = action === "show" ? (sub ? [sub, ...restTail] : restTail) : restTail;

  const resolveNameMaybe = async (): Promise<string> => {
    const positional = tail[0] && !tail[0].startsWith("-") ? tail.shift() : undefined;
    const flag = popFlagValue(tail, "--account");
    return await resolveExistingAccount(flag ?? positional);
  };

  if (action === "open") {
    const account = await resolveNameMaybe();
    // Best-effort: weekly/sessions quota isn’t reliably available via public APIs.
    // Open ChatGPT UI and let the user inspect usage/quota for that account.
    console.log(`Open quota UI for account: ${account}`);
    openUrl("https://chatgpt.com/");
    return;
  }

  if (action === "set") {
    const account = await resolveNameMaybe();
    const note = tail.join(" ").trim();
    if (!note) die("Usage: polycodex quota set [<name>] <note...>");
    await updateAccountMeta(account, { quotaNote: note, lastUsedAt: new Date().toISOString() });
    console.log(`Saved quota note for ${account}`);
    return;
  }

  if (action === "clear") {
    const account = await resolveNameMaybe();
    await updateAccountMeta(account, { quotaNote: undefined, lastUsedAt: new Date().toISOString() });
    console.log(`Cleared quota note for ${account}`);
    return;
  }

  // show
  const account = await resolveNameMaybe();
  const meta = await readAccountMeta(account);
  if (meta?.quotaNote) {
    console.log(`${account}: ${meta.quotaNote}`);
  } else {
    console.log(`${account}: quota unknown (not available via stable public API).`);
    console.log(`Try: polycodex quota open ${account}`);
  }
}

async function cmdLegacyProfile(rest: string[]): Promise<void> {
  // Back-compat: `profile` maps to `accounts`.
  await cmdAccounts(rest);
}

async function cmdLegacyAuth(rest: string[]): Promise<void> {
  // Back-compat: `auth import/apply` supported, but primary UX is `accounts import/use`.
  const [action, ...tail] = rest;
  if (!action) die("Missing auth action.");

  if (action === "import") {
    const account = popFlagValue(tail, "--account") ?? tail[0];
    const resolved = await resolveExistingAccount(account);
    await importDefaultAuthToAccount(resolved);
    console.log(`Imported ~/.codex/auth.json into account: ${resolved}`);
    return;
  }

  if (action === "apply") {
    const name = tail[0];
    if (!name) die("Missing account name. Usage: polycodex auth apply <name>");
    const force = popFlag(tail, "--force");
    if (tail.slice(1).length) {
      const extra = tail.slice(1).filter((x) => x !== "--force");
      if (extra.length) die(`Unknown flag(s): ${extra.join(" ")}`);
    }
    const resolved = await resolveExistingAccount(name);
    await applyAccountAuthToDefault(resolved, force);
    console.log(`Applied account auth to ~/.codex/auth.json: ${resolved}`);
    return;
  }

  die(`Unknown auth action: ${action}`);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (!args.length) {
    await runCodexWithAccount({ codexArgs: [], forceLock: false, restorePreviousAuth: false });
    return;
  }

  const [cmd, ...rest] = args;
  if (!cmd) return;

  if (cmd === "help" || cmd === "--help" || cmd === "-h") {
    printHelp();
    return;
  }

  if (cmd === "--version" || cmd === "-V") {
    // Keep in sync with package.json manually.
    console.log("polycodex 0.1.0");
    return;
  }

  // Clear commands + aliases
  if (cmd === "accounts" || cmd === "account") return await cmdAccounts(rest);
  if (cmd === "ls") return await cmdAccounts(["list", ...rest]);
  if (cmd === "add") return await cmdAccounts(["add", ...rest]);
  if (cmd === "rm") return await cmdAccounts(["remove", ...rest]);
  if (cmd === "rename") return await cmdAccounts(["rename", ...rest]);
  if (cmd === "use" || cmd === "switch") return await cmdAccounts(["use", ...rest]);
  if (cmd === "current" || cmd === "which") return await cmdAccounts(["current", ...rest]);
  if (cmd === "import") return await cmdAccounts(["import", ...rest]);

  if (cmd === "run") return await cmdRun(rest);
  if (cmd === "status" || cmd === "whoami") return await cmdStatus(rest);
  if (cmd === "quota") return await cmdQuota(rest);

  // Legacy commands (keep for published compatibility)
  if (cmd === "profile") return await cmdLegacyProfile(rest);
  if (cmd === "auth") return await cmdLegacyAuth(rest);

  // Passthrough to codex args using current account.
  // `polycodex codex ...` drops the explicit "codex".
  if (cmd === "codex") {
    await runCodexWithAccount({ codexArgs: rest, forceLock: false, restorePreviousAuth: false });
    return;
  }

  await runCodexWithAccount({ codexArgs: args, forceLock: false, restorePreviousAuth: false });
}

await main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exit(1);
});
