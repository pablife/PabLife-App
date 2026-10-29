import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";

export type ActiveUserRow = {
  user_id: string;
  email: string;
  phone: string;
  created_at: string;
};

type UserRow = {
  id: string;
  email: string;
  status: string;
  deleted_at: string | null;
  phone: string;
  created_at: string;
};

export async function getActiveUserOrThrow(
  userClient: SupabaseClient,
  authUserId: string,
): Promise<ActiveUserRow> {
  const { data, error } = await userClient
    .from("tb_users")
    .select("id, email, status, deleted_at, phone, created_at")
    .eq("id", authUserId)
    .maybeSingle<UserRow>();

  if (error) {
    throw new AppError(500, "USER_FETCH_FAILED", "Failed to fetch user");
  }

  if (!data) {
    throw new AppError(403, "USER_NOT_FOUND", "User not found");
  }

  if (data.status !== "active" || data.deleted_at !== null) {
    throw new AppError(403, "USER_INACTIVE", "User is inactive");
  }

  return {
    user_id: data.id,
    email: data.email,
    phone: data.phone,
    created_at: data.created_at,
  };
}
