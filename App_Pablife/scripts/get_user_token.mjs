#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function parseEnvFile(contents) {
  const env = {};
  const lines = contents.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!match) continue;

    const key = match[1];
    let value = match[2].trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    env[key] = value;
  }

  return env;
}

function loadEnvFile(explicitPath) {
  const candidates = [];

  if (explicitPath) {
    candidates.push(explicitPath);
  } else {
    candidates.push(".env", path.join("supabase", "functions", ".env"));
  }

  for (const candidate of candidates) {
    const absolute = path.resolve(process.cwd(), candidate);
    if (fs.existsSync(absolute)) {
      const contents = fs.readFileSync(absolute, "utf8");
      return { env: parseEnvFile(contents), path: absolute };
    }
  }

  return { env: {}, path: null };
}

function requireValue(name, value, hint) {
  if (value && String(value).trim().length > 0) return String(value).trim();
  const suffix = hint ? ` (${hint})` : "";
  throw new Error(`Missing ${name}${suffix}`);
}

async function main() {
  const argv = process.argv.slice(2);
  const envFlagIndex = argv.indexOf("--env");
  const envPath = envFlagIndex >= 0 ? argv[envFlagIndex + 1] : null;

  const { env: fileEnv, path: loadedPath } = loadEnvFile(envPath);

  const supabaseUrl =
    process.env.SUPABASE_URL ?? fileEnv.SUPABASE_URL ?? "";
  const supabaseAnonKey =
    process.env.SUPABASE_ANON_KEY ?? fileEnv.SUPABASE_ANON_KEY ?? "";
  const email =
    process.env.SUPABASE_EMAIL ??
    fileEnv.SUPABASE_EMAIL ??
    process.env.EMAIL ??
    fileEnv.EMAIL ??
    "";
  const password =
    process.env.SUPABASE_PASSWORD ??
    fileEnv.SUPABASE_PASSWORD ??
    process.env.PASSWORD ??
    fileEnv.PASSWORD ??
    "";

  requireValue("SUPABASE_URL", supabaseUrl, loadedPath ?? "no .env found");
  requireValue("SUPABASE_ANON_KEY", supabaseAnonKey, loadedPath ?? "no .env found");
  requireValue("SUPABASE_EMAIL", email, loadedPath ?? "no .env found");
  requireValue("SUPABASE_PASSWORD", password, loadedPath ?? "no .env found");

  const endpoint = `${supabaseUrl.replace(/\/$/, "")}/auth/v1/token?grant_type=password`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      apikey: supabaseAnonKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  });

  const payloadText = await response.text();
  let payload;
  try {
    payload = JSON.parse(payloadText);
  } catch {
    payload = { raw: payloadText };
  }

  if (!response.ok) {
    console.error("Login failed:", payload);
    process.exit(1);
  }

  const output = {
    access_token: payload.access_token,
    refresh_token: payload.refresh_token,
    token_type: payload.token_type,
    expires_in: payload.expires_in,
  };

  console.log(JSON.stringify(output, null, 2));
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});
