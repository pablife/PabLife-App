import { AppError } from "../utils/errors.ts";
import { MpClient } from "./mpClient.ts";
import type { MpPaymentResponse } from "./types.ts";

export type CreatePaymentParams = {
  client: MpClient;
  payer_email: string;
  card_token_id: string;
  payment_method_id: string;
  amount: number;
  external_reference_pay: string;
  idempotency_key: string;
  additional_info?: {
    ip_address: string | null;
    payer: {
      first_name: string;
      last_name?: string;
      phone: {
        area_code: string;
        number: string;
      } | null;
      registration_date?: string | null;
      is_prime_user: string;
      is_first_purchase_online: string;
    };
  };
};

export async function createImmediatePayment(
  params: CreatePaymentParams,
): Promise<{
  payment_id: string;
  status: string | null;
  status_detail: string | null;
  raw: MpPaymentResponse;
}> {
  const payload = {
    token: params.card_token_id,
    transaction_amount: params.amount,
    installments: 1,
    payment_method_id: params.payment_method_id,
    payer: {
      email: params.payer_email,
    },
    external_reference: params.external_reference_pay,
    additional_info: params.additional_info,
  };

  const response = await params.client.request<MpPaymentResponse>(
    "/v1/payments",
    {
      method: "POST",
      body: payload,
      idempotencyKey: params.idempotency_key,
    },
  );

  if (!response.id) {
    throw new AppError(502, "MP_RESPONSE_INVALID", "Missing payment id");
  }

  return {
    payment_id: String(response.id),
    status: response.status ?? null,
    status_detail: response.status_detail ?? null,
    raw: response,
  };
}
