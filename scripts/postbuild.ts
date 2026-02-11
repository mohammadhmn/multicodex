import fs from "node:fs/promises";

const outputPath = new URL("../dist/cli.js", import.meta.url);
const shebang = "#!/usr/bin/env node\n";

async function main(): Promise<void> {
  let contents = await fs.readFile(outputPath, "utf8");
  if (!contents.startsWith("#!")) {
    contents = shebang + contents;
    await fs.writeFile(outputPath, contents, { mode: 0o755 });
  }

  // Ensure executable bit on platforms that support it.
  try {
    await fs.chmod(outputPath, 0o755);
  } catch {
    // ignore (e.g. Windows)
  }
}

await main();

