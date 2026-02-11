import { afterEach, describe, expect, test } from "bun:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { loadConfig, saveConfig } from "../src/config";

let tmpRoot: string | undefined;

async function withTempHome(): Promise<string> {
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "multicodex-test-"));
  process.env.MULTICODEX_HOME = tmpRoot;
  return tmpRoot;
}

afterEach(async () => {
  if (tmpRoot) {
    await fs.rm(tmpRoot, { recursive: true, force: true });
    tmpRoot = undefined;
  }
  delete process.env.MULTICODEX_HOME;
});

describe("config", () => {
  test("loads default config when missing", async () => {
    await withTempHome();
    const cfg = await loadConfig();
    expect(cfg.version).toBe(2);
    expect(Object.keys(cfg.accounts).length).toBe(0);
  });

  test("saves and loads config", async () => {
    await withTempHome();
    await saveConfig({
      version: 2,
      currentAccount: "work",
      accounts: {
        work: {},
      },
    });
    const cfg = await loadConfig();
    expect(cfg.currentAccount).toBe("work");
    expect(cfg.accounts.work).toBeTruthy();
  });
});
