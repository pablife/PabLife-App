import type { JsonObject } from "../types/mercadopago.ts";
import { parseExternalReference } from "./external_reference.ts";
import type { Topic } from "./router.ts";
import { MercadoPagoService } from "./mercadopago_client.ts";
import {
  buildExternalReferenceFromSubscription,
  findSubscriptionById,
  findSubscriptionByPreapprovalId,
  type SubscriptionContext,
  type SubscriptionRow,
} from "./subscription_context.ts";
import { safeError, safeLog } from "./safe_log.ts";
import { getSupabaseClient } from "./supabase_client.ts";

type ProcessingResult = {
  processed: boolean;
  processingNotes?: string | null;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function toStringValue(value: unknown): string | null {
  if (typeof value === "string") return value;
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  return null;
}

function toNumberValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function addDays(value: string, days: number): string | null {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  const next = new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
  return next.toISOString();
}

function getJsonObject(snapshot: unknown): JsonObject | null {
  if (!isRecord(snapshot)) return null;
  return snapshot as JsonObject;
}

function getNestedRecord(
  record: Record<string, unknown>,
  key: string,
): Record<string, unknown> | null {
  const value = record[key];
  return isRecord(value) ? value : null;
}

function isTempPreapprovalId(value: string | null): boolean {
  return typeof value === "string" && value.startsWith("TEMP-");
}

function buildSubscriptionUpdateFromPreapproval(
  preapproval: JsonObject,
  subscription: SubscriptionRow,
  externalReferenceRaw: string,
): Record<string, unknown> {
  const payload: Record<string, unknown> = {};

  const status = toStringValue(preapproval.status);
  if (status === "cancelled") {
    payload.status = "cancelled";
    if (!subscription.cancelled_at) {
      payload.cancelled_at =
        toStringValue(preapproval.date_last_updated) ??
        new Date().toISOString();
    }
  }

  const preapprovalId = toStringValue(preapproval.id);
  if (
    preapprovalId &&
    (subscription.mp_preapproval_id === null ||
      isTempPreapprovalId(subscription.mp_preapproval_id))
  ) {
    payload.mp_preapproval_id = preapprovalId;
  }

  if (subscription.external_reference !== externalReferenceRaw) {
    payload.external_reference = externalReferenceRaw;
  }

  if (!subscription.has_preapproval) {
    payload.has_preapproval = true;
  }

  const autoRecurring = getNestedRecord(preapproval, "auto_recurring");

  const reason = toStringValue(preapproval.reason);
  if (!subscription.reason && reason) payload.reason = reason;

  const payerId =
    toStringValue(preapproval.payer_id) ??
    toStringValue(getNestedRecord(preapproval, "payer")?.id);
  if (!subscription.mp_payer_id && payerId) payload.mp_payer_id = payerId;

  const payerEmail =
    toStringValue(preapproval.payer_email) ??
    toStringValue(getNestedRecord(preapproval, "payer")?.email);
  if (!subscription.mp_payer_email && payerEmail) {
    payload.mp_payer_email = payerEmail;
  }

  const frequency = toNumberValue(autoRecurring?.frequency);
  if (subscription.frequency === null && frequency !== null) {
    payload.frequency = frequency;
  }

  const frequencyType = toStringValue(autoRecurring?.frequency_type);
  if (!subscription.frequency_type && frequencyType) {
    payload.frequency_type = frequencyType;
  }

  const transactionAmount = toNumberValue(autoRecurring?.transaction_amount);
  if (subscription.transaction_amount === null && transactionAmount !== null) {
    payload.transaction_amount = transactionAmount;
  }

  const currencyId = toStringValue(autoRecurring?.currency_id);
  if (!subscription.currency_id && currencyId) payload.currency_id = currencyId;

  // start_date is handled only on first approved payment.
  const endDate = toStringValue(autoRecurring?.end_date);
  if (endDate && endDate !== subscription.end_date) {
    payload.end_date = endDate;
  }

  const mpDateCreated = toStringValue(preapproval.date_created);
  if (!subscription.mp_date_created && mpDateCreated) {
    payload.mp_date_created = mpDateCreated;
  }

  const mpLastModified =
    toStringValue(preapproval.last_modified) ??
    toStringValue(preapproval.date_last_updated);
  if (!subscription.mp_last_modified && mpLastModified) {
    payload.mp_last_modified = mpLastModified;
  }

  const nextPaymentDate = toStringValue(preapproval.next_payment_date);
  if (!subscription.next_payment_date && nextPaymentDate) {
    payload.next_payment_date = nextPaymentDate;
  }

  const renewedAt = toStringValue(preapproval.renewed_at);
  if (!subscription.renewed_at && renewedAt) payload.renewed_at = renewedAt;

  return payload;
}

async function processPreapproval(
  snapshot: unknown,
  context: SubscriptionContext,
): Promise<ProcessingResult> {
  const preapproval = getJsonObject(snapshot);
  if (!preapproval) {
    return {
      processed: false,
      processingNotes: "invalid_preapproval_snapshot",
    };
  }

  const updatePayload = buildSubscriptionUpdateFromPreapproval(
    preapproval,
    context.subscription,
    context.externalReferenceRaw,
  );

  if (Object.keys(updatePayload).length === 0) {
    return { processed: true };
  }

  const client = getSupabaseClient();
  const { error: updateError } = await client
    .from("tb_user_subscriptions")
    .update(updatePayload)
    .eq("id", context.subscription.id);

  if (updateError) {
    return { processed: false, processingNotes: "subscription_update_failed" };
  }

  return { processed: true };
}

function extractPaymentDateFields(payment: JsonObject): {
  endDate?: string;
  nextPaymentDate?: string;
} {
  const dateOfExpiration = toStringValue(payment.date_of_expiration);
  const metadata = getNestedRecord(payment, "metadata");
  const nextPaymentDate = toStringValue(metadata?.next_payment_date);

  const payload: { endDate?: string; nextPaymentDate?: string } = {};
  if (dateOfExpiration) payload.endDate = dateOfExpiration;
  if (nextPaymentDate) payload.nextPaymentDate = nextPaymentDate;
  return payload;
}

function extractAuthorizedPaymentPreapprovalId(
  response: JsonObject,
): string | null {
  const results = response.results;
  if (!Array.isArray(results)) return null;

  for (const item of results) {
    if (!isRecord(item)) continue;
    const preapprovalId = toStringValue(item.preapproval_id);
    if (preapprovalId) return preapprovalId;
  }

  return null;
}

async function resolvePaymentFallbackContext(
  payment: JsonObject,
  mpService: MercadoPagoService,
): Promise<{ context: SubscriptionContext | null; processingNotes: string }> {
  const paymentId = toStringValue(payment.id);
  if (!paymentId) {
    safeLog("[mercadopago-webhook] payment_fallback_missing_payment_id", {
      error: safeError("missing_payment_id"),
    });
    return {
      context: null,
      processingNotes: "payment_fallback_missing_payment_id",
    };
  }

  let searchResponse: JsonObject;
  try {
    searchResponse = await mpService.searchAuthorizedPayments(paymentId);
  } catch (error) {
    safeLog("[mercadopago-webhook] authorized_payments_search_failed", {
      error: safeError(error),
      mp_payment_id: paymentId,
    });
    return {
      context: null,
      processingNotes: "authorized_payments_search_failed",
    };
  }

  const preapprovalId = extractAuthorizedPaymentPreapprovalId(searchResponse);
  if (!preapprovalId) {
    safeLog("[mercadopago-webhook] authorized_payment_preapproval_missing", {
      mp_payment_id: paymentId,
      error: safeError("preapproval_id_missing"),
    });
    return {
      context: null,
      processingNotes: "authorized_payment_preapproval_missing",
    };
  }

  const subscription = await findSubscriptionByPreapprovalId(preapprovalId);
  if (!subscription) {
    safeLog("[mercadopago-webhook] subscription_not_found_for_preapproval", {
      mp_preapproval_id: preapprovalId,
      error: safeError("subscription_not_found"),
    });
    return {
      context: null,
      processingNotes: "subscription_not_found_for_preapproval",
    };
  }

  return {
    context: {
      subscription,
      externalReferenceRaw:
        buildExternalReferenceFromSubscription(subscription),
    },
    processingNotes: "resolved_via_payment_fallback",
  };
}

async function resolvePreapprovalFallbackContext(
  preapproval: JsonObject,
  mpService: MercadoPagoService,
): Promise<{ context: SubscriptionContext | null; processingNotes: string }> {
  const preapprovalId = toStringValue(preapproval.id);
  if (!preapprovalId) {
    safeLog(
      "[mercadopago-webhook] subscription_fallback_missing_preapproval_id",
      {
        error: safeError("missing_preapproval_id"),
      },
    );
    return {
      context: null,
      processingNotes: "subscription_fallback_missing_preapproval_id",
    };
  }

  const subscription = await findSubscriptionByPreapprovalId(preapprovalId);
  if (!subscription) {
    const status = toStringValue(preapproval.status);
    if (status !== "cancelled") {
      try {
        await mpService.updatePreapprovalStatus(preapprovalId, "cancelled");
      } catch (error) {
        safeLog("[mercadopago-webhook] mp_cancel_failed", {
          error: safeError(error),
          mp_preapproval_id: preapprovalId,
        });
      }
    }

    safeLog("[mercadopago-webhook] subscription_not_found_for_preapproval", {
      mp_preapproval_id: preapprovalId,
      error: safeError("subscription_not_found"),
    });
    return {
      context: null,
      processingNotes: "subscription_not_found_for_preapproval",
    };
  }

  return {
    context: {
      subscription,
      externalReferenceRaw:
        buildExternalReferenceFromSubscription(subscription),
    },
    processingNotes: "resolved_via_preapproval_fallback",
  };
}

function buildTransactionPayload(
  payment: JsonObject,
  externalReferenceRaw: string,
  subscriptionId: string,
): Record<string, unknown> {
  const payer = getNestedRecord(payment, "payer");
  const transactionDetails = getNestedRecord(payment, "transaction_details");

  const payload: Record<string, unknown> = {
    user_subscription_id: subscriptionId,
    mp_payment_id: toNumberValue(payment.id) ?? payment.id,
    external_reference: externalReferenceRaw,
    status: toStringValue(payment.status) ?? "pending",
    status_detail: toStringValue(payment.status_detail),
    transaction_amount: toNumberValue(payment.transaction_amount),
    currency_id: toStringValue(payment.currency_id),
    installments: toNumberValue(payment.installments),
    payment_method_id: toStringValue(payment.payment_method_id),
    payment_type_id: toStringValue(payment.payment_type_id),
    issuer_id: toStringValue(payment.issuer_id),
    mp_payer_id: toStringValue(payer?.id),
    mp_payer_email: toStringValue(payer?.email),
    mp_date_created: toStringValue(payment.date_created),
    mp_date_approved: toStringValue(payment.date_approved),
    mp_date_last_updated: toStringValue(payment.date_last_updated),
    net_received_amount: toNumberValue(transactionDetails?.net_received_amount),
    total_paid_amount: toNumberValue(transactionDetails?.total_paid_amount),
    refunded_amount: toNumberValue(payment.transaction_amount_refunded),
    mp_payment_snapshot: payment,
  };

  Object.keys(payload).forEach((key) => {
    if (payload[key] === null || payload[key] === undefined) {
      delete payload[key];
    }
  });

  return payload;
}

async function processPayment(
  snapshot: unknown,
  context: SubscriptionContext,
  mpService: MercadoPagoService,
): Promise<ProcessingResult> {
  const payment = getJsonObject(snapshot);
  if (!payment) {
    return { processed: false, processingNotes: "invalid_payment_snapshot" };
  }

  const paymentId = toStringValue(payment.id);
  if (!paymentId) {
    return { processed: false, processingNotes: "missing_payment_id" };
  }
  const paymentIdValue = toNumberValue(payment.id) ?? paymentId;

  const client = getSupabaseClient();
  const subscription = context.subscription;
  const mpPreapprovalId =
    subscription.mp_preapproval_id ??
    toStringValue(payment.preapproval_id) ??
    toStringValue(getNestedRecord(payment, "metadata")?.preapproval_id);

  if (subscription.external_reference !== context.externalReferenceRaw) {
    const { error: externalRefError } = await client
      .from("tb_user_subscriptions")
      .update({ external_reference: context.externalReferenceRaw })
      .eq("id", subscription.id);

    if (externalRefError) {
      return {
        processed: false,
        processingNotes: "subscription_external_reference_update_failed",
      };
    }
  }

  const { data: existingTx, error: existingTxError } = await client
    .from("tb_subscription_transactions")
    .select("id, attempt_no, status")
    .eq("mp_payment_id", paymentIdValue)
    .maybeSingle();

  if (existingTxError) {
    return { processed: false, processingNotes: "transaction_lookup_failed" };
  }

  const status = toStringValue(payment.status) ?? "pending";
  const isRejected = status === "rejected" || status === "cancelled";
  const isApproved = status === "approved";

  const transactionPayload = buildTransactionPayload(
    payment,
    context.externalReferenceRaw,
    subscription.id,
  );

  let attemptNo = existingTx?.attempt_no ?? 1;
  const wasApproved = existingTx?.status === "approved";

  if (existingTx) {
    if (isRejected) attemptNo += 1;
    const updatePayload: Record<string, unknown> = {
      ...transactionPayload,
      attempt_no: attemptNo,
    };

    const { error: updateError } = await client
      .from("tb_subscription_transactions")
      .update(updatePayload)
      .eq("id", existingTx.id);

    if (updateError) {
      return { processed: false, processingNotes: "transaction_update_failed" };
    }
  } else {
    const insertPayload: Record<string, unknown> = {
      ...transactionPayload,
      attempt_no: isRejected ? 1 : 1,
    };

    const { error: insertError } = await client
      .from("tb_subscription_transactions")
      .insert(insertPayload);

    if (insertError) {
      return { processed: false, processingNotes: "transaction_insert_failed" };
    }
  }

  const { data: approvedTx, error: approvedTxError } = await client
    .from("tb_subscription_transactions")
    .select("id")
    .eq("user_subscription_id", subscription.id)
    .eq("status", "approved")
    .neq("mp_payment_id", paymentIdValue)
    .limit(1);

  if (approvedTxError) {
    return {
      processed: false,
      processingNotes: "approved_transaction_lookup_failed",
    };
  }

  const hasPriorApproved = Boolean(approvedTx?.length);

  if (isApproved) {
    const { endDate, nextPaymentDate } = extractPaymentDateFields(payment);
    const subscriptionUpdate: Record<string, unknown> = {
      mp_last_modified: toStringValue(payment.date_last_updated),
      renewed_at: new Date().toISOString(),
    };

    let shouldActivate = subscription.status !== "active";
    if (subscription.status === "cancelled") {
      shouldActivate = false;
      if (mpPreapprovalId) {
        try {
          const preapproval = await mpService.getPreapproval(mpPreapprovalId);
          const mpStatus = toStringValue(
            (preapproval as Record<string, unknown>).status,
          );
          if (mpStatus !== "cancelled") {
            shouldActivate = true;
          }
        } catch (error) {
          safeLog("[mercadopago-webhook] mp_preapproval_status_lookup_failed", {
            error: safeError(error),
            mp_preapproval_id: mpPreapprovalId,
          });
        }
      }
    }

    if (shouldActivate) {
      subscriptionUpdate.status = "active";
    }

    if (endDate) subscriptionUpdate.end_date = endDate;
    if (nextPaymentDate) subscriptionUpdate.next_payment_date = nextPaymentDate;

    const payer = getNestedRecord(payment, "payer");
    const payerId = toStringValue(payer?.id);
    const payerEmail = toStringValue(payer?.email);
    if (payerId) subscriptionUpdate.mp_payer_id = payerId;
    if (payerEmail) subscriptionUpdate.mp_payer_email = payerEmail;

    const transactionAmount = toNumberValue(payment.transaction_amount);
    if (transactionAmount !== null) {
      subscriptionUpdate.transaction_amount = transactionAmount;
    }
    const currencyId = toStringValue(payment.currency_id);
    if (currencyId) subscriptionUpdate.currency_id = currencyId;

    const isFirstApproved = !hasPriorApproved;
    const approvedAt =
      toStringValue(payment.date_approved) ?? new Date().toISOString();
    const createdAt = subscription.created_at ?? approvedAt;

    if (isFirstApproved) {
      subscriptionUpdate.has_first_payment = true;
      subscriptionUpdate.started_at = createdAt;
      subscriptionUpdate.start_date = createdAt;
      const newEndDate = addDays(createdAt, 30);
      if (newEndDate) {
        subscriptionUpdate.end_date = newEndDate;
      }
    } else {
      const fallbackStart = subscription.mp_date_created ?? approvedAt;
      if (!subscription.started_at) {
        subscriptionUpdate.started_at = fallbackStart;
      }
      if (!subscription.has_first_payment) {
        subscriptionUpdate.has_first_payment = true;
      }
    }

    if (!isFirstApproved && !wasApproved) {
      const resolvedStartedAt =
        (subscriptionUpdate.started_at as string | undefined) ??
        subscription.started_at ??
        approvedAt;
      const endDateBase =
        subscription.end_date ??
        subscription.start_date ??
        subscription.started_at ??
        resolvedStartedAt;
      const newEndDate = addDays(endDateBase, 30);
      if (newEndDate) {
        subscriptionUpdate.end_date = newEndDate;
      }
    }

    const { error: subscriptionUpdateError } = await client
      .from("tb_user_subscriptions")
      .update(subscriptionUpdate)
      .eq("id", subscription.id);

    if (subscriptionUpdateError) {
      return {
        processed: false,
        processingNotes: "subscription_update_failed_after_approval",
      };
    }
  }

  if (isRejected && !hasPriorApproved && subscription.status === "pending") {
    if (!subscription.has_preapproval && !subscription.has_first_payment) {
      if (mpPreapprovalId && !isTempPreapprovalId(mpPreapprovalId)) {
        try {
          await mpService.updatePreapprovalStatus(mpPreapprovalId, "cancelled");
        } catch {
          return { processed: false, processingNotes: "mp_cancel_failed" };
        }
      }

      const { error: cancelError } = await client
        .from("tb_user_subscriptions")
        .update({
          status: "cancelled",
          cancelled_at: new Date().toISOString(),
        })
        .eq("id", subscription.id);

      if (cancelError) {
        return {
          processed: false,
          processingNotes: "subscription_cancel_failed_after_rejection",
        };
      }

      return { processed: true };
    }

    const { error: resetError } = await client
      .from("tb_user_subscriptions")
      .update({
        status: "pending",
        has_first_payment: false,
        started_at: null,
      })
      .eq("id", subscription.id);

    if (resetError) {
      return {
        processed: false,
        processingNotes: "subscription_reset_failed_after_rejection",
      };
    }
  }

  if (isRejected && attemptNo >= 3) {
    if (mpPreapprovalId) {
      try {
        await mpService.updatePreapprovalStatus(mpPreapprovalId, "cancelled");
      } catch {
        return { processed: false, processingNotes: "mp_cancel_failed" };
      }
    }

    const { error: cancelError } = await client
      .from("tb_user_subscriptions")
      .update({
        status: "cancelled",
        cancelled_at: new Date().toISOString(),
      })
      .eq("id", subscription.id);

    if (cancelError) {
      return {
        processed: false,
        processingNotes: "subscription_cancel_failed_after_retries",
      };
    }
  }

  return { processed: true };
}

export async function processWebhookEvent(params: {
  topic: Topic;
  snapshot: unknown;
  requestId: string;
  mpService: MercadoPagoService;
}): Promise<ProcessingResult> {
  if (
    params.topic !== "payment" &&
    params.topic !== "subscription_preapproval"
  ) {
    return {
      processed: false,
      processingNotes: "unsupported_topic_for_processing",
    };
  }

  const snapshot = params.snapshot;
  const record = getJsonObject(snapshot);
  if (!record) {
    return { processed: false, processingNotes: "snapshot_not_object" };
  }

  const externalReferenceValue = record.external_reference;
  const externalReference = parseExternalReference(externalReferenceValue);

  let context: SubscriptionContext | null = null;
  let resolutionNotes: string | null = null;

  if (externalReference) {
    const subscription = await findSubscriptionById(
      externalReference.userSubscriptionId,
    );
    if (!subscription) {
      safeLog(
        "[mercadopago-webhook] subscription_not_found_for_external_reference",
        {
          user_subscription_id: externalReference.userSubscriptionId,
          error: safeError("subscription_not_found"),
        },
      );
      return {
        processed: false,
        processingNotes: "subscription_not_found_for_external_reference",
      };
    }

    context = {
      subscription,
      externalReferenceRaw: externalReference.rawValue,
    };
  } else {
    if (params.topic === "payment") {
      const fallback = await resolvePaymentFallbackContext(
        record,
        params.mpService,
      );
      if (!fallback.context) {
        return { processed: false, processingNotes: fallback.processingNotes };
      }
      context = fallback.context;
      resolutionNotes = fallback.processingNotes;
    } else {
      const fallback = await resolvePreapprovalFallbackContext(
        record,
        params.mpService,
      );
      if (!fallback.context) {
        return { processed: false, processingNotes: fallback.processingNotes };
      }
      context = fallback.context;
      resolutionNotes = fallback.processingNotes;
    }
  }

  if (!context) {
    return {
      processed: false,
      processingNotes: "subscription_context_missing",
    };
  }

  const processingResult =
    params.topic === "subscription_preapproval"
      ? await processPreapproval(snapshot, context)
      : await processPayment(snapshot, context, params.mpService);

  if (processingResult.processed) {
    return {
      processed: true,
      processingNotes: processingResult.processingNotes ?? resolutionNotes,
    };
  }

  return processingResult;
}
