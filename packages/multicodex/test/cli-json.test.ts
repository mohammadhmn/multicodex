import { describe, expect, test } from "bun:test";
import { mkdtempSync, rmSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

function runCli(args: string[], env: Record<string, string>): { code: number; stdout: string; stderr: string } {
  const res = spawnSync(process.execPath, ["run", "src/cli.ts", ...args], {
    cwd: path.resolve(import.meta.dirname, ".."),
    env: { ...process.env, ...env },
    encoding: "utf8",
  });
  return {
    code: typeof res.status === "number" ? res.status : 1,
    stdout: res.stdout ?? "",
    stderr: res.stderr ?? "",
  };
}

function parseJson(stdout: string): any {
  return JSON.parse(stdout.trim() || "null");
}

describe("--json output", () => {
  test("accounts list/add/current/use", async () => {
    const tmp = mkdtempSync(path.join(os.tmpdir(), "multicodex-cli-"));
    try {
      const home = path.join(tmp, "home");
      const multicodexHome = path.join(tmp, "multicodex");

      {
        const res = runCli(["accounts", "list", "--json"], { HOME: home, MULTICODEX_HOME: multicodexHome });
        expect(res.code).toBe(0);
        expect(res.stderr).toBe("");
        const json = parseJson(res.stdout);
        expect(json.ok).toBe(true);
        expect(json.command).toBe("accounts.list");
        expect(json.data.accounts).toEqual([]);
      }

      {
        const res = runCli(["accounts", "add", "work", "--json"], { HOME: home, MULTICODEX_HOME: multicodexHome });
        expect(res.code).toBe(0);
        expect(res.stderr).toBe("");
        const json = parseJson(res.stdout);
        expect(json.ok).toBe(true);
        expect(json.command).toBe("accounts.add");
        expect(json.data.account).toBe("work");
      }

      {
        const res = runCli(["accounts", "current", "--json"], { HOME: home, MULTICODEX_HOME: multicodexHome });
        expect(res.code).toBe(0);
        expect(res.stderr).toBe("");
        const json = parseJson(res.stdout);
        expect(json.ok).toBe(true);
        expect(json.data.currentAccount).toBe("work");
      }

      {
        const res = runCli(["use", "work", "--json"], { HOME: home, MULTICODEX_HOME: multicodexHome });
        expect(res.code).toBe(0);
        expect(res.stderr).toBe("");
        const json = parseJson(res.stdout);
        expect(json.ok).toBe(true);
        expect(json.data.currentAccount).toBe("work");
      }
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
  });
});

