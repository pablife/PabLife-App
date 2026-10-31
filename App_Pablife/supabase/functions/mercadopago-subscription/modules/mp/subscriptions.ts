import { AppError } from "../utils/errors.ts";
import { MpClient } from "./mpClient.ts";
import type { MpPreapprovalResponse } from "./types.ts";

export type SubscriptionPlanPayload = {
  // Sem plano no Mercado Pago (modo de teste), a assinatura usa só os valores
  // de auto_recurring abaixo.
  preapproval_plan_id: string | null;
  frequency: number;
  frequency_type: "months" | "days";
  transaction_amount: number;
  currency_id: string;
};

export type CreateSubscriptionParams = {
  client: MpClient;
  payer_email: string;
  card_token_id: string;
  reason: string;
  plan: SubscriptionPlanPayload;
  external_reference_sub: string;
  idempotency_key?: string;
};

export async function createSubscriptionNextCycle(
  params: CreateSubscriptionParams,
): Promise<{
  preapproval_id: string;
  status: string | null;
  raw: MpPreapprovalResponse;
}> {
  const payload = {
    // Sem plano, o Mercado Pago exige o endereço de retorno (o plano já o tem).
    ...(params.plan.preapproval_plan_id
      ? { preapproval_plan_id: params.plan.preapproval_plan_id }
      : { back_url: "https://app.pablife.com.br" }),
    payer_email: params.payer_email,
    reason: params.reason,
    external_reference: params.external_reference_sub,
    status: "authorized",
    card_token_id: params.card_token_id,
    auto_recurring: {
      frequency: params.plan.frequency,
      frequency_type: params.plan.frequency_type,
      transaction_amount: params.plan.transaction_amount,
      currency_id: params.plan.currency_id,
    },
  };

  const response = await params.client.request<MpPreapprovalResponse>(
    "/preapproval",
    {
      method: "POST",
      body: payload,
      idempotencyKey: params.idempotency_key,
    },
  );

  if (!response.id) {
    throw new AppError(502, "MP_RESPONSE_INVALID", "Missing preapproval id");
  }

  return {
    preapproval_id: response.id,
    status: response.status ?? null,
    raw: response,
  };
}

export async function cancelSubscription(
  client: MpClient,
  preapproval_id: string,
): Promise<void> {
  await client.request(`/preapproval/${preapproval_id}`, {
    method: "PUT",
    body: {
      status: "cancelled",
    },
  });
}
