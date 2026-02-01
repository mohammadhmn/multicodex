import { afterEach, describe, expect, test } from "bun:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { acquireAuthLock } from "../src/lock";
import { authLockDir } from "../src/paths";

let tmpRoot: string | undefined;

async function setup(): Promise<void> {
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "polycodex-test-"));
  process.env.POLYCODEX_HOME = tmpRoot;
}

afterEach(async () => {
  if (tmpRoot) {
    await fs.rm(tmpRoot, { recursive: true, force: true });
    tmpRoot = undefined;
  }
  delete process.env.POLYCODEX_HOME;
});

describe("lock", () => {
  test("acquires and releases lock", async () => {
    await setup();
    const lock = await acquireAuthLock({ account: "work", force: false });
    const stat = await fs.lstat(authLockDir());
    expect(stat.isDirectory()).toBe(true);
    await lock.release();
    await expect(fs.lstat(authLockDir())).rejects.toBeTruthy();
  });

  test("prevents double acquire without force", async () => {
    await setup();
    const lock = await acquireAuthLock({ account: "work", force: false });
    await expect(acquireAuthLock({ account: "personal", force: false })).rejects.toBeTruthy();
    await lock.release();
  });

  test("force reclaims lock", async () => {
    await setup();
    const lock = await acquireAuthLock({ account: "work", force: false });
    const lock2 = await acquireAuthLock({ account: "personal", force: true });
    await lock2.release();
    // Releasing the first lock should be a no-op (directory already removed).
    await lock.release();
  });
});
