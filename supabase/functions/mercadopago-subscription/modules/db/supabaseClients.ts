import { createClient } from "../../deps.ts";
import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";

function requireEnv(key: string): string {
  const value = Deno.env.get(key);
  if (!value) {
    throw new AppError(500, "MISSING_ENV", `Missing environment variable: ${key}`);
  }
  return value;
}

export function createUserClient(req: Request): SupabaseClient {
  const supabaseUrl = requireEnv("SUPABASE_URL");
  const supabaseAnonKey = requireEnv("SUPABASE_ANON_KEY");
  const authorization = req.headers.get("Authorization") ??
    req.headers.get("authorization") ?? "";

  return createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        Authorization: authorization,
      },
    },
  });
}

export function createAdminClient(): SupabaseClient {
  const supabaseUrl = requireEnv("SUPABASE_URL");
  const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
