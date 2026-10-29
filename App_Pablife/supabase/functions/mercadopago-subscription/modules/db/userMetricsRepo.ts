import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";

export async function hasActiveSubscription(
  client: SupabaseClient,
  userId: string,
): Promise<boolean> {
  const { data, error } = await client
    .from("tb_user_subscriptions")
    .select("id")
    .eq("user_id", userId)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (error) {
    throw new AppError(
      500,
      "SUBSCRIPTION_FETCH_FAILED",
      "Failed to fetch subscription status",
    );
  }

  return !!data;
}

export async function hasApprovedPayments(
  client: SupabaseClient,
  userId: string,
): Promise<boolean> {
  const { data, error } = await client
    .from("tb_subscription_transactions")
    .select("id, tb_user_subscriptions!inner(user_id)")
    .eq("tb_user_subscriptions.user_id", userId)
    .eq("status", "approved")
    .limit(1)
    .maybeSingle();

  if (error) {
    throw new AppError(
      500,
      "SUBSCRIPTION_TRANSACTION_FETCH_FAILED",
      "Failed to fetch subscription transactions",
    );
  }

  return !!data;
}
