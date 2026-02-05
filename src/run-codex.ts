import { withAccountAuth } from "./auth-swap";
import { spawn } from "node:child_process";

export type RunCodexOptions = {
  account: string;
  codexArgs: string[];
  forceLock: boolean;
  restorePreviousAuth: boolean;
};

export async function runCodex(opts: RunCodexOptions): Promise<number> {
  return await withAccountAuth(
    {
      account: opts.account,
      forceLock: opts.forceLock,
      restorePreviousAuth: opts.restorePreviousAuth,
    },
    async () => {
      return await new Promise<number>((resolve, reject) => {
        const child = spawn("codex", opts.codexArgs, {
          stdio: "inherit",
          env: { ...process.env },
        });
        child.on("error", (error) => {
          const code = (error as NodeJS.ErrnoException | undefined)?.code;
          if (code === "ENOENT") {
            return reject(
              new Error("`codex` not found in PATH. Install Codex CLI and try again."),
            );
          }
          return reject(error);
        });
        child.on("exit", (code, signal) => {
          if (typeof code === "number") return resolve(code);
          // If terminated by signal, follow common convention.
          return resolve(signal ? 128 : 1);
        });
      });
    },
  );
}

export type RunCodexCaptureOptions = RunCodexOptions;

export type RunCodexCaptureResult = {
  exitCode: number;
  stdout: string;
  stderr: string;
};

export async function runCodexCapture(opts: RunCodexCaptureOptions): Promise<RunCodexCaptureResult> {
  return await withAccountAuth(
    {
      account: opts.account,
      forceLock: opts.forceLock,
      restorePreviousAuth: opts.restorePreviousAuth,
    },
    async () => {
      return await new Promise<RunCodexCaptureResult>((resolve, reject) => {
        const child = spawn("codex", opts.codexArgs, {
          stdio: ["inherit", "pipe", "pipe"],
          env: { ...process.env },
        });

        let stdout = "";
        let stderr = "";
        child.stdout?.setEncoding("utf8");
        child.stderr?.setEncoding("utf8");
        child.stdout?.on("data", (chunk) => {
          stdout += String(chunk);
        });
        child.stderr?.on("data", (chunk) => {
          stderr += String(chunk);
        });

        child.on("error", (error) => {
          const code = (error as NodeJS.ErrnoException | undefined)?.code;
          if (code === "ENOENT") {
            return reject(new Error("`codex` not found in PATH. Install Codex CLI and try again."));
          }
          return reject(error);
        });

        child.on("exit", (code, signal) => {
          const exitCode = typeof code === "number" ? code : signal ? 128 : 1;
          resolve({ exitCode, stdout, stderr });
        });
      });
    },
  );
}
