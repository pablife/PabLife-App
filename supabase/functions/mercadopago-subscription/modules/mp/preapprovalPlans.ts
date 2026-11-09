import { AppError } from "../utils/errors.ts";
import { MpClient } from "./mpClient.ts";

export type MpPreapprovalPlan = {
  id: string;
  reason: string | null;
  transaction_amount: number;
  currency_id: string;
  frequency: number;
  frequency_type: "months" | "days";
};

type MpPreapprovalPlanResponse = {
  id?: string;
  reason?: string;
  auto_recurring?: {
    transaction_amount?: number;
    currency_id?: string;
    frequency?: number;
    frequency_type?: "months" | "days";
  };
};

function requireField<T>(value: T | null | undefined, field: string): T {
  if (value === null || value === undefined) {
    throw new AppError(502, "MP_RESPONSE_INVALID", `Missing ${field}`);
  }
  return value;
}

export async function getPreapprovalPlan(
  client: MpClient,
  preapprovalPlanId: string,
): Promise<MpPreapprovalPlan> {
  const response = await client.request<MpPreapprovalPlanResponse>(
    `/preapproval_plan/${preapprovalPlanId}`,
    { method: "GET" },
  );

  const auto = response.auto_recurring ?? {};

  return {
    id: requireField(response.id, "id"),
    reason: response.reason ?? null,
    transaction_amount: requireField(auto.transaction_amount, "auto_recurring.transaction_amount"),
    currency_id: requireField(auto.currency_id, "auto_recurring.currency_id"),
    frequency: requireField(auto.frequency, "auto_recurring.frequency"),
    frequency_type: requireField(auto.frequency_type, "auto_recurring.frequency_type"),
  };
}
