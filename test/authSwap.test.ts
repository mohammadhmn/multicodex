import { afterEach, describe, expect, test } from "bun:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { addAccount } from "../src/profiles";
import { applyAccountAuthToDefault, importDefaultAuthToAccount, withAccountAuth } from "../src/authSwap";
import { accountAuthPath, defaultCodexAuthPath } from "../src/paths";

const originalHome = process.env.HOME;

let tmpHome: string | undefined;
let tmpPoly: string | undefined;

async function setup(): Promise<void> {
  tmpHome = await fs.mkdtemp(path.join(os.tmpdir(), "polycodex-home-"));
  tmpPoly = await fs.mkdtemp(path.join(os.tmpdir(), "polycodex-root-"));
  process.env.HOME = tmpHome;
  process.env.POLYCODEX_HOME = tmpPoly;
  await addAccount({ name: "work" });
}

afterEach(async () => {
  if (tmpHome) await fs.rm(tmpHome, { recursive: true, force: true });
  if (tmpPoly) await fs.rm(tmpPoly, { recursive: true, force: true });
  tmpHome = undefined;
  tmpPoly = undefined;
  if (originalHome === undefined) delete process.env.HOME;
  else process.env.HOME = originalHome;
  delete process.env.POLYCODEX_HOME;
});

describe("authSwap", () => {
  test("imports default auth into account without modifying default auth", async () => {
    await setup();
    await fs.mkdir(path.dirname(defaultCodexAuthPath()), { recursive: true, mode: 0o700 });
    await fs.writeFile(defaultCodexAuthPath(), "DEFAULT\n", { mode: 0o600 });

    await importDefaultAuthToAccount("work");
    const accountAuth = await fs.readFile(accountAuthPath("work"), "utf8");
    expect(accountAuth).toBe("DEFAULT\n");
    const defaultAuth = await fs.readFile(defaultCodexAuthPath(), "utf8");
    expect(defaultAuth).toBe("DEFAULT\n");
  });

  test("apply writes account auth into ~/.codex/auth.json", async () => {
    await setup();
    await fs.mkdir(path.dirname(accountAuthPath("work")), { recursive: true, mode: 0o700 });
    await fs.writeFile(accountAuthPath("work"), "WORK\n", { mode: 0o600 });

    await applyAccountAuthToDefault("work", false);
    const defaultAuth = await fs.readFile(defaultCodexAuthPath(), "utf8");
    expect(defaultAuth).toBe("WORK\n");
  });

  test("withAccountAuth restores previous auth when requested", async () => {
    await setup();
    await fs.mkdir(path.dirname(defaultCodexAuthPath()), { recursive: true, mode: 0o700 });
    await fs.writeFile(defaultCodexAuthPath(), "PREV\n", { mode: 0o600 });
    await fs.mkdir(path.dirname(accountAuthPath("work")), { recursive: true, mode: 0o700 });
    await fs.writeFile(accountAuthPath("work"), "WORK\n", { mode: 0o600 });

    await withAccountAuth(
      { account: "work", forceLock: false, restorePreviousAuth: true },
      async () => {
        const during = await fs.readFile(defaultCodexAuthPath(), "utf8");
        expect(during).toBe("WORK\n");
        await fs.writeFile(defaultCodexAuthPath(), "UPDATED\n", { mode: 0o600 });
      },
    );

    const restored = await fs.readFile(defaultCodexAuthPath(), "utf8");
    expect(restored).toBe("PREV\n");

    const snapped = await fs.readFile(accountAuthPath("work"), "utf8");
    expect(snapped).toBe("UPDATED\n");
  });
});

