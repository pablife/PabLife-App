import type { SupabaseClient } from "../deps.ts";
import { AppError } from "./utils/errors.ts";

export async function getAuthUserId(
  userClient: SupabaseClient,
  req: Request,
): Promise<string> {
  const authHeader = req.headers.get("Authorization") ??
    req.headers.get("authorization");

  if (!authHeader) {
    throw new AppError(401, "UNAUTHORIZED", "Missing Authorization header");
  }

  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    throw new AppError(401, "UNAUTHORIZED", "Invalid Authorization header");
  }

  const { data, error } = await userClient.auth.getUser();
  if (error || !data?.user?.id) {
    throw new AppError(401, "UNAUTHORIZED", "Invalid token");
  }

  return data.user.id;
}
