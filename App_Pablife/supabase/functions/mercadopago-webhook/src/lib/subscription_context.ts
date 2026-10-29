import { getSupabaseClient } from "./supabase_client.ts";
import { buildExternalReference } from "./external_reference.ts";

const SUBSCRIPTION_SELECT_FIELDS = [
  "id",
  "user_id",
  "plan_id",
  "mp_preapproval_id",
  "external_reference",
  "status",
  "has_first_payment",
  "started_at",
  "mp_date_created",
  "has_preapproval",
  "reason",
  "frequency",
  "frequency_type",
  "transaction_amount",
  "currency_id",
  "start_date",
  "end_date",
  "mp_payer_id",
  "mp_payer_email",
  "mp_last_modified",
  "next_payment_date",
  "renewed_at",
  "cancelled_at",
  "created_at",
].join(", ");

export type SubscriptionRow = {
  id: string;
  user_id: string;
  plan_id: string;
  mp_preapproval_id: string | null;
  external_reference: string | null;
  status: string | null;
  has_first_payment: boolean | null;
  started_at: string | null;
  mp_date_created: string | null;
  has_preapproval: boolean | null;
  reason: string | null;
  frequency: number | null;
  frequency_type: string | null;
  transaction_amount: number | null;
  currency_id: string | null;
  start_date: string | null;
  end_date: string | null;
  mp_payer_id: string | null;
  mp_payer_email: string | null;
  mp_last_modified: string | null;
  next_payment_date: string | null;
  renewed_at: string | null;
  cancelled_at: string | null;
  created_at: string | null;
};

export type SubscriptionContext = {
  subscription: SubscriptionRow;
  externalReferenceRaw: string;
};

export function buildExternalReferenceFromSubscription(
  subscription: SubscriptionRow,
): string {
  return buildExternalReference({
    userId: subscription.user_id,
    planId: subscription.plan_id,
    userSubscriptionId: subscription.id,
  });
}

export async function findSubscriptionById(
  id: string,
): Promise<SubscriptionRow | null> {
  const client = getSupabaseClient();
  const { data, error } = await client
    .from("tb_user_subscriptions")
    .select(SUBSCRIPTION_SELECT_FIELDS)
    .eq("id", id)
    .maybeSingle();

  if (error || !data) return null;
  return data as SubscriptionRow;
}

export async function findSubscriptionByPreapprovalId(
  preapprovalId: string,
): Promise<SubscriptionRow | null> {
  const client = getSupabaseClient();
  const { data, error } = await client
    .from("tb_user_subscriptions")
    .select(SUBSCRIPTION_SELECT_FIELDS)
    .eq("mp_preapproval_id", preapprovalId)
    .maybeSingle();

  if (error || !data) return null;
  return data as SubscriptionRow;
}
