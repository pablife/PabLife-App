import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";
import type { MpPreapprovalResponse } from "../mp/types.ts";

export type UserSubscriptionRow = {
  id: string;
  user_id: string;
  plan_id: string;
  mp_preapproval_id: string;
  external_reference: string;
  status: string;
  has_first_payment: boolean;
  has_preapproval: boolean;
  started_at: string | null;
  reason: string | null;
  frequency: number | null;
  frequency_type: string | null;
  transaction_amount: number | null;
  currency_id: string | null;
  start_date: string | null;
  end_date: string | null;
  mp_payer_id: string | null;
  mp_payer_email: string | null;
  mp_date_created: string | null;
  mp_last_modified: string | null;
  next_payment_date: string | null;
  renewed_at: string | null;
  cancelled_at: string | null;
};

const SELECT_FIELDS =
  "id, user_id, plan_id, mp_preapproval_id, external_reference, status, has_first_payment, has_preapproval, started_at, reason, frequency, frequency_type, transaction_amount, currency_id, start_date, end_date, mp_payer_id, mp_payer_email, mp_date_created, mp_last_modified, next_payment_date, renewed_at, cancelled_at";

export async function findOpenSubscriptionForPlan(
  client: SupabaseClient,
  params: { userId: string; planId: string },
): Promise<UserSubscriptionRow | null> {
  const { data, error } = await client
    .from("tb_user_subscriptions")
    .select(SELECT_FIELDS)
    .eq("user_id", params.userId)
    .eq("plan_id", params.planId)
    .in("status", ["pending", "active"])
    .maybeSingle<UserSubscriptionRow>();

  if (error) {
    throw new AppError(
      500,
      "SUBSCRIPTION_FETCH_FAILED",
      "Failed to fetch subscription",
    );
  }

  return data ?? null;
}

export async function createPendingSubscription(
  client: SupabaseClient,
  params: {
    id: string;
    userId: string;
    planId: string;
    mpPreapprovalId: string;
    externalReference: string;
    reason: string | null;
    frequency: number | null;
    frequencyType: string | null;
    transactionAmount: number | null;
    currencyId: string | null;
  },
): Promise<UserSubscriptionRow> {
  const { data, error } = await client
    .from("tb_user_subscriptions")
    .insert({
      id: params.id,
      user_id: params.userId,
      plan_id: params.planId,
      mp_preapproval_id: params.mpPreapprovalId,
      external_reference: params.externalReference,
      status: "pending",
      has_first_payment: false,
      has_preapproval: false,
      reason: params.reason,
      frequency: params.frequency,
      frequency_type: params.frequencyType,
      transaction_amount: params.transactionAmount,
      currency_id: params.currencyId,
    })
    .select(SELECT_FIELDS)
    .single<UserSubscriptionRow>();

  if (error || !data) {
    console.log("SUBSCRIPTION_CREATE_FAILED", error, data);
    throw new AppError(
      500,
      "SUBSCRIPTION_CREATE_FAILED",
      "Failed to create subscription",
    );
  }

  return data;
}

export async function cancelUserSubscription(
  client: SupabaseClient,
  subscriptionId: string,
): Promise<void> {
  const { error } = await client
    .from("tb_user_subscriptions")
    .update({
      status: "cancelled",
      cancelled_at: new Date().toISOString(),
    })
    .eq("id", subscriptionId);

  if (error) {
    throw new AppError(
      500,
      "SUBSCRIPTION_CANCEL_FAILED",
      "Failed to cancel subscription",
    );
  }
}

export async function markSubscriptionFirstPayment(
  client: SupabaseClient,
  subscriptionId: string,
): Promise<void> {
  const { error } = await client
    .from("tb_user_subscriptions")
    .update({ has_first_payment: true })
    .eq("id", subscriptionId);

  if (error) {
    throw new AppError(
      500,
      "SUBSCRIPTION_UPDATE_FAILED",
      "Failed to update subscription payment",
    );
  }
}

function resolveMpLastModified(
  preapproval: MpPreapprovalResponse,
): string | null {
  return preapproval.last_modified ?? preapproval.date_last_updated ?? null;
}

export async function updateSubscriptionAfterPreapproval(
  client: SupabaseClient,
  params: {
    subscription: UserSubscriptionRow;
    preapproval: MpPreapprovalResponse;
    externalReference?: string;
  },
): Promise<UserSubscriptionRow> {
  if (!params.preapproval.id) {
    throw new AppError(502, "MP_RESPONSE_INVALID", "Missing preapproval id");
  }

  const auto = params.preapproval.auto_recurring ?? {};
  const payer = params.preapproval.payer ?? {};

  const updatePayload: Record<string, unknown> = {
    has_preapproval: true,
    mp_preapproval_id: params.preapproval.id,
  };

  if (!params.subscription.external_reference && params.externalReference) {
    updatePayload.external_reference = params.externalReference;
  }

  if (!params.subscription.reason && params.preapproval.reason) {
    updatePayload.reason = params.preapproval.reason;
  }

  if (params.subscription.frequency === null && auto.frequency !== undefined) {
    updatePayload.frequency = auto.frequency;
  }

  if (!params.subscription.frequency_type && auto.frequency_type) {
    updatePayload.frequency_type = auto.frequency_type;
  }

  if (
    params.subscription.transaction_amount === null &&
    auto.transaction_amount !== undefined
  ) {
    updatePayload.transaction_amount = auto.transaction_amount;
  }

  if (!params.subscription.currency_id && auto.currency_id) {
    updatePayload.currency_id = auto.currency_id;
  }

  // start_date is handled only on first approved payment via webhook.
  const endDate = auto.end_date ?? null;
  if (endDate && endDate !== params.subscription.end_date) {
    updatePayload.end_date = endDate;
  }

  if (!params.subscription.mp_date_created && params.preapproval.date_created) {
    updatePayload.mp_date_created = params.preapproval.date_created;
  }

  const lastModified = resolveMpLastModified(params.preapproval);
  if (!params.subscription.mp_last_modified && lastModified) {
    updatePayload.mp_last_modified = lastModified;
  }

  if (
    !params.subscription.next_payment_date &&
    params.preapproval.next_payment_date
  ) {
    updatePayload.next_payment_date = params.preapproval.next_payment_date;
  }

  if (!params.subscription.renewed_at && params.preapproval.renewed_at) {
    updatePayload.renewed_at = params.preapproval.renewed_at;
  }

  const payerId = params.preapproval.payer_id ?? payer.id ?? null;
  if (!params.subscription.mp_payer_id && payerId) {
    updatePayload.mp_payer_id = payerId;
  }

  const payerEmail = params.preapproval.payer_email ?? payer.email ?? null;
  if (!params.subscription.mp_payer_email && payerEmail) {
    updatePayload.mp_payer_email = payerEmail;
  }

  const { data, error } = await client
    .from("tb_user_subscriptions")
    .update(updatePayload)
    .eq("id", params.subscription.id)
    .select(SELECT_FIELDS)
    .single<UserSubscriptionRow>();

  if (error || !data) {
    throw new AppError(
      500,
      "SUBSCRIPTION_UPDATE_FAILED",
      "Failed to update subscription",
    );
  }

  return data;
}
