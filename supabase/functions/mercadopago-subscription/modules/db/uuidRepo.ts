import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";

export async function generateUuidV7(client: SupabaseClient): Promise<string> {
  const { data, error } = await client.rpc("uuidv7");

  if (error || !data) {
    throw new AppError(500, "UUID_GENERATE_FAILED", "Failed to generate uuid");
  }

  if (typeof data !== "string") {
    throw new AppError(
      500,
      "UUID_GENERATE_FAILED",
      "Invalid uuid response",
    );
  }

  return data;
}
