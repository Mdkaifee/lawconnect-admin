import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const configPath = resolve("tsr.config.json");

function fail(message) {
  console.error(`Build config check failed: ${message}`);
  process.exit(1);
}

let raw;
try {
  raw = readFileSync(configPath, "utf8");
} catch (error) {
  fail(`Cannot read ${configPath}: ${error.message}`);
}

if (!raw.trim()) {
  fail("tsr.config.json is empty. Restore the TanStack Router config before deploying.");
}

let config;
try {
  config = JSON.parse(raw);
} catch (error) {
  fail(`tsr.config.json is not valid JSON: ${error.message}`);
}

const requiredFields = {
  routesDirectory: "./src/routes",
  generatedRouteTree: "./src/routeTree.gen.ts",
};

for (const [key, expected] of Object.entries(requiredFields)) {
  if (config[key] !== expected) {
    fail(`tsr.config.json must include "${key}": "${expected}".`);
  }
}

console.log("Build config check passed.");
