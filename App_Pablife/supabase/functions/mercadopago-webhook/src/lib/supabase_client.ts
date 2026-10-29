import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { config } from "../config.ts";

let supabaseClient: ReturnType<typeof createClient> | null = null;

export function getSupabaseClient() {
  if (supabaseClient) return supabaseClient;
  if (!config.supabaseUrl || !config.supabaseServiceRoleKey) {
    throw new Error(
      "Supabase credentials are missing; cannot access database.",
    );
  }
  supabaseClient = createClient(
    config.supabaseUrl,
    config.supabaseServiceRoleKey,
    {
      auth: { persistSession: false },
    },
  );
  return supabaseClient;
}
