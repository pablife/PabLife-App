import type { SupabaseClient } from "../../deps.ts";
import { createAdminClient } from "./supabaseClients.ts";
import { AppError } from "../utils/errors.ts";

export type SubscriptionPlan = {
  id: string;
  reason: string;
  preapproval_plan_id: string;
};

type PlanRow = {
  id: string;
  reason: string;
  preapproval_plan_id: string;
  deleted_at: string | null;
};

async function fetchPlan(
  client: SupabaseClient,
  planId: string,
): Promise<{ data: PlanRow | null; error: Error | null }> {
  const { data, error } = await client
    .from("tb_subscription_plans")
    .select("id, reason, preapproval_plan_id, deleted_at")
    .eq("id", planId)
    .maybeSingle<PlanRow>();

  return { data: data ?? null, error: error ?? null };
}

export async function getPlanOrThrow(
  userClient: SupabaseClient,
  planId: string,
): Promise<SubscriptionPlan> {
  let result = await fetchPlan(userClient, planId);

  if (!result.data) {
    try {
      const adminClient = createAdminClient();
      result = await fetchPlan(adminClient, planId);
    } catch (error) {
      throw new AppError(500, "PLAN_FETCH_FAILED", "Failed to fetch plan");
    }
  }

  if (result.error) {
    throw new AppError(500, "PLAN_FETCH_FAILED", "Failed to fetch plan");
  }

  if (!result.data) {
    throw new AppError(404, "PLAN_NOT_FOUND", "Plan not found");
  }

  if (result.data.deleted_at !== null) {
    throw new AppError(403, "PLAN_INACTIVE", "Plan is inactive");
  }

  if (!result.data.preapproval_plan_id) {
    throw new AppError(500, "PLAN_INVALID", "Missing preapproval_plan_id");
  }

  return {
    id: result.data.id,
    reason: result.data.reason,
    preapproval_plan_id: result.data.preapproval_plan_id,
  };
}
