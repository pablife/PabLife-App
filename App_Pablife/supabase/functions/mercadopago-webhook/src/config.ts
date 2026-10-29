export type AppConfig = {
  mercadopagoAccessToken: string;
  mercadopagoWebhookSecret: string;
  mercadopagoApiBase: string;
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  enablePersistence: boolean;
};

function requireEnv(key: string): string {
  safeLog(`[mercadopago-webhook] load_env_${key}`);
  const value = Deno.env.get(key);
  if (!value) {
    throw new Error(`Missing required env var: ${key}`);
  }
  return value;
}

function parseBoolean(
  value: string | undefined,
  defaultValue: boolean,
): boolean {
  if (value === undefined) return defaultValue;
  const normalized = value.trim().toLowerCase();
  if (["1", "true", "yes", "y", "on"].includes(normalized)) return true;
  if (["0", "false", "no", "n", "off"].includes(normalized)) return false;
  return defaultValue;
}

const enablePersistence = parseBoolean(
  Deno.env.get("ENABLE_PERSISTENCE"),
  true,
);
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

if (enablePersistence) {
  if (!supabaseUrl) throw new Error("Missing required env var: SUPABASE_URL");
  if (!supabaseServiceRoleKey) {
    throw new Error("Missing required env var: SUPABASE_SERVICE_ROLE_KEY");
  }
}

export const config: AppConfig = {
  mercadopagoAccessToken: requireEnv("MERCADOPAGO_ACCESS_TOKEN"),
  mercadopagoWebhookSecret: requireEnv("MERCADOPAGO_WEBHOOK_SECRET"),
  mercadopagoApiBase: requireEnv("MERCADOPAGO_API_BASE"),
  supabaseUrl,
  supabaseServiceRoleKey,
  enablePersistence,
};
import { safeLog } from "./lib/safe_log.ts";
