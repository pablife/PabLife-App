import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";

export type SubscriptionTransactionInsert = {
  user_subscription_id: string;
  mp_payment_id: number | string;
  external_reference?: string | null;
  status: string;
  status_detail?: string | null;
  transaction_amount?: number | null;
  currency_id?: string | null;
  installments?: number | null;
  payment_method_id?: string | null;
  payment_type_id?: string | null;
  issuer_id?: string | null;
  mp_payer_id?: string | null;
  mp_payer_email?: string | null;
  mp_date_created?: string | null;
  mp_date_approved?: string | null;
  mp_date_last_updated?: string | null;
  net_received_amount?: number | null;
  total_paid_amount?: number | null;
  refunded_amount?: number | null;
  mp_payment_snapshot?: unknown;
};

function isDuplicateError(error: { code?: string; message?: string } | null): boolean {
  if (!error) return false;
  if (error.code === "23505") return true;
  if (error.message && error.message.includes("duplicate key value")) return true;
  return false;
}

export async function insertSubscriptionTransaction(
  client: SupabaseClient,
  payload: SubscriptionTransactionInsert,
): Promise<{ inserted: boolean }> {
  const { error } = await client
    .from("tb_subscription_transactions")
    .insert(payload);

  if (error) {
    if (isDuplicateError(error)) {
      return { inserted: false };
    }

    throw new AppError(
      500,
      "SUBSCRIPTION_TRANSACTION_CREATE_FAILED",
      "Failed to create subscription transaction",
    );
  }

  return { inserted: true };
}
