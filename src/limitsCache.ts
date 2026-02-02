import fs from "node:fs/promises";
import path from "node:path";
import type { RateLimitSnapshot } from "./codexRpc";
import { multicodexHomeDir } from "./paths";

type LimitsCache = {
  version: 1;
  accounts: Record<
    string,
    {
      snapshot: RateLimitSnapshot;
      fetchedAt: number;
    }
  >;
};

function cachePath(): string {
  return path.join(multicodexHomeDir(), "limits-cache.json");
}

async function safeReadFile(p: string): Promise<string | undefined> {
  try {
    return await fs.readFile(p, "utf8");
  } catch (error) {
    const code = (error as NodeJS.ErrnoException | undefined)?.code;
    if (code === "ENOENT") return undefined;
    throw error;
  }
}

async function writeFileAtomic(p: string, data: string): Promise<void> {
  await fs.mkdir(path.dirname(p), { recursive: true, mode: 0o700 });
  const tmp = `${p}.tmp.${process.pid}.${Math.random().toString(16).slice(2)}`;
  await fs.writeFile(tmp, data, { mode: 0o600 });
  await fs.rename(tmp, p);
}

async function loadCache(): Promise<LimitsCache> {
  const raw = await safeReadFile(cachePath());
  if (!raw) return { version: 1, accounts: {} };
  try {
    const parsed = JSON.parse(raw) as LimitsCache;
    if (parsed && parsed.version === 1 && parsed.accounts) return parsed;
  } catch {
    // fallthrough
  }
  return { version: 1, accounts: {} };
}

async function saveCache(cache: LimitsCache): Promise<void> {
  await writeFileAtomic(cachePath(), JSON.stringify(cache, null, 2) + "\n");
}

export async function getCachedLimits(
  account: string,
  ttlMs: number,
): Promise<{ snapshot: RateLimitSnapshot; ageMs: number } | null> {
  const cache = await loadCache();
  const entry = cache.accounts[account];
  if (!entry) return null;
  const ageMs = Date.now() - entry.fetchedAt;
  if (ageMs > ttlMs) return null;
  return { snapshot: entry.snapshot, ageMs };
}

export async function setCachedLimits(account: string, snapshot: RateLimitSnapshot): Promise<void> {
  const cache = await loadCache();
  cache.accounts[account] = { snapshot, fetchedAt: Date.now() };
  await saveCache(cache);
}
