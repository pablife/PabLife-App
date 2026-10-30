import type { SupabaseClient } from "../../deps.ts";
import { AppError } from "../utils/errors.ts";

export type ValidCoupon = {
  coupon_id: string;
  free_days: number;
};

type ValidateCouponResult = {
  valid?: boolean;
  reason?: string;
  coupon_id?: string;
  free_days?: number;
};

const REASON_MESSAGES: Record<string, string> = {
  not_found: "Cupom não encontrado",
  inactive: "Cupom inativo",
  not_started: "Cupom ainda não está valendo",
  expired: "Cupom expirado",
  exhausted: "Cupom esgotado",
  already_used: "Você já usou este cupom",
};

/**
 * Confere o cupom para o usuário da requisição (usa o client do usuário,
 * porque a função validate_coupon olha o auth.uid()).
 */
export async function validateCouponOrThrow(
  userClient: SupabaseClient,
  code: string,
): Promise<ValidCoupon> {
  const { data, error } = await userClient.rpc("validate_coupon", {
    p_code: code,
  });

  if (error) {
    throw new AppError(500, "COUPON_CHECK_FAILED", "Failed to check coupon");
  }

  const result = (data ?? {}) as ValidateCouponResult;
  if (!result.valid || !result.coupon_id || !result.free_days) {
    const reason = result.reason ?? "not_found";
    throw new AppError(
      400,
      "COUPON_INVALID",
      REASON_MESSAGES[reason] ?? "Cupom inválido",
    );
  }

  return { coupon_id: result.coupon_id, free_days: result.free_days };
}

export async function recordCouponRedemption(
  adminClient: SupabaseClient,
  params: {
    couponId: string;
    userId: string;
    userSubscriptionId: string;
    planId: string;
    isTest: boolean;
  },
): Promise<void> {
  const { error } = await adminClient.from("tb_coupon_redemptions").insert({
    coupon_id: params.couponId,
    user_id: params.userId,
    user_subscription_id: params.userSubscriptionId,
    plan_id: params.planId,
    is_test: params.isTest,
  });

  if (error) {
    throw new AppError(
      500,
      "COUPON_REDEEM_FAILED",
      "Failed to record coupon redemption",
    );
  }
}

/** Ativa a assinatura pelo período grátis do cupom, sem pagamento. */
export async function activateSubscriptionWithCoupon(
  adminClient: SupabaseClient,
  params: { subscriptionId: string; startDate: Date; endDate: Date },
): Promise<void> {
  const { error } = await adminClient
    .from("tb_user_subscriptions")
    .update({
      status: "active",
      has_first_payment: true,
      start_date: params.startDate.toISOString(),
      end_date: params.endDate.toISOString(),
      next_payment_date: params.endDate.toISOString(),
    })
    .eq("id", params.subscriptionId);

  if (error) {
    throw new AppError(
      500,
      "SUBSCRIPTION_UPDATE_FAILED",
      "Failed to activate subscription with coupon",
    );
  }
}
