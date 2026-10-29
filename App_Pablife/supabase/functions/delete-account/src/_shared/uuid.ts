import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { log } from "./logger.ts";

export async function generateUuidV7(
  client: SupabaseClient
): Promise<string> {
  const { data, error } = await client.rpc("uuidv7");

  if (error || !data) {
    log("Failed to generate uuidv7", { error });
    throw new Error("UUIDV7_GENERATION_FAILED");
  }

  if (typeof data !== "string") {
    log("Invalid uuidv7 response", { data });
    throw new Error("UUIDV7_GENERATION_FAILED");
  }

  return data;
}
