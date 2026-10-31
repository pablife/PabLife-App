import "./deps.ts";

import { handleOptions } from "./_shared/cors.ts";
import { jsonError, jsonOk, parseJsonSafely } from "./_shared/http.ts";
import { InputSchema } from "./modules/schemas.ts";
import { getAuthUserId } from "./modules/auth.ts";
import {
  createAdminClient,
  createUserClient,
} from "./modules/db/supabaseClients.ts";
import { getActiveUserOrThrow } from "./modules/db/usersRepo.ts";
import {
  hasActiveSubscription,
  hasApprovedPayments,
} from "./modules/db/userMetricsRepo.ts";
import {
  getPlanOrThrow,
  getPlanPricingOrThrow,
} from "./modules/db/plansRepo.ts";
import {
  MP_ACCESS_TOKEN_ENV,
  MP_PUBLIC_KEY_ENV,
  TEST_MODE,
} from "./modules/mode.ts";
import {
  cancelUserSubscription,
  createPendingSubscription,
  findOpenSubscriptionForPlan,
  markSubscriptionFirstPayment,
  updateSubscriptionAfterPreapproval,
} from "./modules/db/userSubscriptionsRepo.ts";
import { insertSubscriptionTransaction } from "./modules/db/subscriptionTransactionsRepo.ts";
import { generateUuidV7 } from "./modules/db/uuidRepo.ts";
import { MpClient } from "./modules/mp/mpClient.ts";
import { createCardToken } from "./modules/mp/cardToken.ts";
import { getPreapprovalById } from "./modules/mp/preapproval.ts";
import { getPreapprovalPlan } from "./modules/mp/preapprovalPlans.ts";
import type {
  MpPaymentResponse,
  MpPreapprovalResponse,
} from "./modules/mp/types.ts";
import { findAuthorizedSubscription } from "./modules/mp/subscriptionsSearch.ts";
import { createSubscriptionNextCycle } from "./modules/mp/subscriptions.ts";
import { createImmediatePayment } from "./modules/mp/payments.ts";
import {
  deriveIdempotencyKeys,
  requireIdempotencyKey,
} from "./modules/utils/idempotency.ts";
import {
  AppError,
  isAppError,
  toErrorPayload,
} from "./modules/utils/errors.ts";
import { safeError, safeLog } from "./modules/utils/safeLog.ts";

function requireEnv(key: string): string {
  const value = Deno.env.get(key);
  if (!value) {
    throw new AppError(
      500,
      "MISSING_ENV",
      `Missing environment variable: ${key}`,
    );
  }
  return value;
}

function buildExternalReference(params: {
  userId: string;
  planId: string;
  subscriptionId: string;
}): string {
  return JSON.stringify({
    user_id: params.userId,
    plan_id: params.planId,
    user_subscription_id: params.subscriptionId,
  });
}

function isTempPreapprovalId(value: string): boolean {
  return value.startsWith("TEMP-");
}

// Cortesias e cupons ficam só no banco, sem assinatura no Mercado Pago.
function isLocalOnlyPreapprovalId(value: string): boolean {
  return value.startsWith("COURTESY-") || value.startsWith("COUPON-");
}

// Cancela a assinatura pendente quando o Mercado Pago recusou antes de
// qualquer cobrança. Se já houve pagamento, não mexe.
async function cancelPendingWithoutCharge(
  adminClient: ReturnType<typeof createAdminClient>,
  subscription: { id: string; status: string; has_first_payment: boolean },
): Promise<void> {
  if (subscription.status !== "pending" || subscription.has_first_payment) {
    return;
  }
  try {
    await cancelUserSubscription(adminClient, subscription.id);
  } catch (error) {
    safeLog("pending_subscription_cancel_failed", {
      user_subscription_id: subscription.id,
      error: safeError(error),
    });
  }
}

function getIpAddress(req: Request): string | null {
  const forwarded = req.headers.get("x-forwarded-for") ?? "";
  if (!forwarded.trim()) return null;
  const first = forwarded.split(",")[0]?.trim();
  return first && first.length > 0 ? first : null;
}

function splitName(fullName: string): { firstName: string; lastName?: string } {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) {
    return { firstName: fullName.trim() };
  }
  const [firstName, ...rest] = parts;
  const lastName = rest.join(" ");
  if (!lastName) {
    return { firstName };
  }
  return { firstName, lastName };
}

function parsePhone(
  value: string | null,
): { areaCode: string; number: string } | null {
  if (!value) return null;
  const digits = value.replace(/\D+/g, "");
  if (digits.length <= 2) return null;
  const areaCode = digits.slice(0, 2);
  const number = digits.slice(2);
  if (!areaCode || !number) return null;
  return { areaCode, number };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return handleOptions();
  }

  if (req.method !== "POST") {
    return jsonError(405, {
      error: {
        code: "METHOD_NOT_ALLOWED",
        message: "Method Not Allowed",
      },
    });
  }

  const { data, error } = await parseJsonSafely(req);
  if (error) {
    return jsonError(400, {
      error: {
        code: "INVALID_JSON",
        message: error,
      },
    });
  }

  const parsed = InputSchema.safeParse(data);
  if (!parsed.success) {
    return jsonError(400, {
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid request payload",
        details: parsed.error.issues,
      },
    });
  }

  const input = parsed.data;
  const requestId = requireIdempotencyKey(req);

  try {
    const mpAccessToken = requireEnv(MP_ACCESS_TOKEN_ENV);
    const mpPublicKey = requireEnv(MP_PUBLIC_KEY_ENV);
    const mpApiBase = requireEnv("MERCADOPAGO_API_BASE");
    const mpClient = new MpClient({
      accessToken: mpAccessToken,
      baseUrl: mpApiBase,
    });

    const userClient = createUserClient(req);
    const authUserId = await getAuthUserId(userClient, req);
    const { user_id, email, phone, created_at } = await getActiveUserOrThrow(
      userClient,
      authUserId,
    );

    // No modo de teste o Mercado Pago só aceita assinaturas de um usuário de
    // teste comprador: o e-mail dele vem de um secret.
    const payerEmail = TEST_MODE
      ? (Deno.env.get("MERCADOPAGO_TEST_PAYER_EMAIL") ?? email)
      : email;

    const plan = await getPlanOrThrow(userClient, input.plan_id);
    if (!plan.preapproval_plan_id) {
      throw new AppError(
        400,
        "PREAPPROVAL_PLAN_REQUIRED",
        "preapproval_plan_id is required",
      );
    }
    // No modo de teste o plano do Mercado Pago de produção não existe na conta
    // de teste: os valores vêm do banco e a assinatura é criada sem plano.
    const mpPlan = TEST_MODE
      ? await (async () => {
        const pricing = await getPlanPricingOrThrow(
          createAdminClient(),
          plan.id,
        );
        return {
          id: plan.preapproval_plan_id,
          reason: pricing.reason,
          transaction_amount: pricing.transaction_amount,
          currency_id: pricing.currency_id,
          frequency: pricing.frequency,
          frequency_type: "months" as const,
        };
      })()
      : await getPreapprovalPlan(mpClient, plan.preapproval_plan_id);

    const reason = mpPlan.reason ?? plan.reason;

    const paymentToken = await createCardToken({
      card: input.card,
      publicKey: mpPublicKey,
      baseUrl: mpApiBase,
    });

    const subscriptionToken = await createCardToken({
      card: input.card,
      publicKey: mpPublicKey,
      baseUrl: mpApiBase,
    });

    const adminClient = createAdminClient();

    let currentSubscription = await findOpenSubscriptionForPlan(adminClient, {
      userId: user_id,
      planId: plan.id,
    });
    let preapprovalSnapshot: MpPreapprovalResponse | null = null;

    if (currentSubscription) {
      if (isLocalOnlyPreapprovalId(currentSubscription.mp_preapproval_id)) {
        // Cortesia ou cupom do mesmo plano (não existe no Mercado Pago):
        // encerra e segue com uma assinatura paga nova.
        await cancelUserSubscription(adminClient, currentSubscription.id);
        currentSubscription = null;
      } else if (!isTempPreapprovalId(currentSubscription.mp_preapproval_id)) {
        preapprovalSnapshot = await getPreapprovalById(
          mpClient,
          currentSubscription.mp_preapproval_id,
        );

        if (
          !preapprovalSnapshot ||
          preapprovalSnapshot.status === "cancelled"
        ) {
          safeLog("subscription_preapproval_missing_or_cancelled", {
            subscription_id: currentSubscription.id,
            mp_preapproval_id: currentSubscription.mp_preapproval_id,
            status: preapprovalSnapshot?.status ?? null,
          });

          await cancelUserSubscription(adminClient, currentSubscription.id);
          currentSubscription = null;
        } else if (!currentSubscription.has_preapproval) {
          const externalReference = buildExternalReference({
            userId: user_id,
            planId: plan.id,
            subscriptionId: currentSubscription.id,
          });

          currentSubscription = await updateSubscriptionAfterPreapproval(
            adminClient,
            {
              subscription: currentSubscription,
              preapproval: preapprovalSnapshot,
              externalReference,
            },
          );
        }
      }
    }

    if (!currentSubscription) {
      const subscriptionId = await generateUuidV7(adminClient);
      const externalReference = buildExternalReference({
        userId: user_id,
        planId: plan.id,
        subscriptionId,
      });

      currentSubscription = await createPendingSubscription(adminClient, {
        id: subscriptionId,
        userId: user_id,
        planId: plan.id,
        mpPreapprovalId: `TEMP-${crypto.randomUUID()}`,
        externalReference,
        reason,
        frequency: mpPlan.frequency,
        frequencyType: mpPlan.frequency_type,
        transactionAmount: mpPlan.transaction_amount,
        currencyId: mpPlan.currency_id,
      });
    }

    const external_reference_sub = buildExternalReference({
      userId: user_id,
      planId: plan.id,
      subscriptionId: currentSubscription.id,
    });
    const external_reference_pay = external_reference_sub;
    const { payKey, subKey } = deriveIdempotencyKeys(
      requestId,
      currentSubscription.id,
    );

    const authorizedSubscription = TEST_MODE
      ? null
      : await findAuthorizedSubscription({
        client: mpClient,
        payer_email: email,
        preapproval_plan_id: plan.preapproval_plan_id,
        external_reference: external_reference_sub,
      });

    if (authorizedSubscription && !currentSubscription.has_preapproval) {
      currentSubscription = await updateSubscriptionAfterPreapproval(
        adminClient,
        {
          subscription: currentSubscription,
          preapproval: {
            id: authorizedSubscription.id,
            status: authorizedSubscription.status,
            auto_recurring: {
              start_date: authorizedSubscription.start_date,
            },
          },
          externalReference: external_reference_sub,
        },
      );
    }

    let payment: null | {
      payment_id: string;
      status: string | null;
      status_detail: string | null;
      raw: MpPaymentResponse;
    } = null;

    const isPrimeUser = await hasActiveSubscription(adminClient, user_id);
    const hasApprovedPayment = await hasApprovedPayments(adminClient, user_id);
    const nameParts = splitName(input.card.name);
    const parsedPhone = parsePhone(phone);
    const additionalInfo = {
      ip_address: getIpAddress(req),
      payer: {
        first_name: nameParts.firstName,
        ...(nameParts.lastName ? { last_name: nameParts.lastName } : {}),
        phone: parsedPhone
          ? { area_code: parsedPhone.areaCode, number: parsedPhone.number }
          : null,
        registration_date: created_at ?? null,
        is_prime_user: isPrimeUser ? "true" : "false",
        is_first_purchase_online: hasApprovedPayment ? "false" : "true",
      },
    };

    if (!currentSubscription.has_first_payment) {
      const paymentMethodId = paymentToken.payment_method_id;
      if (!paymentMethodId) {
        throw new AppError(
          502,
          "PAYMENT_METHOD_INVALID",
          "Missing payment method id",
        );
      }

      try {
        safeLog("createImmediatePayment:", {
          client: mpClient,
          payer_email: payerEmail,
          card_token_id: paymentToken.card_token_id,
          payment_method_id: paymentMethodId,
          amount: mpPlan.transaction_amount,
          external_reference_pay,
          idempotency_key: payKey,
          additional_info: additionalInfo,
        });
        payment = await createImmediatePayment({
          client: mpClient,
          payer_email: payerEmail,
          card_token_id: paymentToken.card_token_id,
          payment_method_id: paymentMethodId,
          amount: mpPlan.transaction_amount,
          external_reference_pay,
          idempotency_key: payKey,
          additional_info: additionalInfo,
        });
      } catch (error) {
        safeLog("payment_create_failed", {
          user_subscription_id: currentSubscription.id,
          error: safeError(error),
        });

        // Nada foi cobrado: encerra a pendência para a pessoa poder tentar de
        // novo (senão o app fica em "pagamento em processamento").
        await cancelPendingWithoutCharge(adminClient, currentSubscription);

        return jsonError(502, {
          error: {
            code: "PAYMENT_CREATE_FAILED",
            message: "Failed to create payment",
            user_subscription_id: currentSubscription.id,
          },
        });
      }

      const normalizedPaymentStatus = payment.status?.toLowerCase() ?? null;
      const isPaymentApproved =
        normalizedPaymentStatus === "approved" ||
        normalizedPaymentStatus === "authorized";

      const isPaymentFail =
        normalizedPaymentStatus === "rejected" ||
        normalizedPaymentStatus === "charged_back" ||
        normalizedPaymentStatus === "refunded" ||
        normalizedPaymentStatus === "cancelled";

      if (!isPaymentApproved || isPaymentFail) {
        console.log(payment);
        safeLog("payment_not_approved", {
          user_subscription_id: currentSubscription.id,
          status: payment.status ?? null,
          status_detail: payment.status_detail ?? null,
        });

        return jsonError(402, {
          error: {
            code: "PAYMENT_NOT_APPROVED",
            message: "Payment not approved",
            user_subscription_id: currentSubscription.id,
            status: payment.status ?? null,
            status_detail: payment.status_detail ?? null,
          },
        });
      }

      await markSubscriptionFirstPayment(adminClient, currentSubscription.id);
      currentSubscription = {
        ...currentSubscription,
        has_first_payment: true,
      };

      const rawPayment = payment.raw;
      const rawPayer = rawPayment.payer;
      const rawDetails = rawPayment.transaction_details;

      const transactionPayload = {
        user_subscription_id: currentSubscription.id,
        mp_payment_id: rawPayment.id ?? payment.payment_id,
        external_reference: external_reference_pay,
        status: "pending",
        status_detail: payment.status_detail,
        transaction_amount:
          rawPayment.transaction_amount ?? mpPlan.transaction_amount,
        currency_id: rawPayment.currency_id ?? mpPlan.currency_id,
        installments: rawPayment.installments ?? 1,
        payment_method_id:
          rawPayment.payment_method_id ?? paymentMethodId,
        payment_type_id: rawPayment.payment_type_id ?? null,
        issuer_id: rawPayment.issuer_id ?? null,
        mp_payer_id: rawPayer?.id ?? null,
        mp_payer_email: rawPayer?.email ?? email ?? null,
        mp_date_created: rawPayment.date_created ?? null,
        mp_date_approved: rawPayment.date_approved ?? null,
        mp_date_last_updated: rawPayment.date_last_updated ?? null,
        net_received_amount: rawDetails?.net_received_amount ?? null,
        total_paid_amount: rawDetails?.total_paid_amount ?? null,
        refunded_amount: rawPayment.transaction_amount_refunded ?? null,
        mp_payment_snapshot: rawPayment,
      };

      const transactionResult = await insertSubscriptionTransaction(
        adminClient,
        transactionPayload,
      );

      if (!transactionResult.inserted) {
        safeLog("subscription_transaction_already_exists", {
          user_subscription_id: currentSubscription.id,
          mp_payment_id: transactionPayload.mp_payment_id,
        });
      }
    }

    let createdSubscription: {
      preapproval_id: string;
      status: string | null;
    } | null = null;

    if (!currentSubscription.has_preapproval) {
      const pendingSubscription = currentSubscription;
      const created = await createSubscriptionNextCycle({
        client: mpClient,
        payer_email: payerEmail,
        card_token_id: subscriptionToken.card_token_id,
        reason,
        plan: {
          preapproval_plan_id: TEST_MODE ? null : plan.preapproval_plan_id,
          frequency: mpPlan.frequency,
          frequency_type: mpPlan.frequency_type,
          transaction_amount: mpPlan.transaction_amount,
          currency_id: mpPlan.currency_id,
        },
        external_reference_sub,
        idempotency_key: subKey,
      }).catch(async (error) => {
        // Recusada antes de qualquer cobrança: libera nova tentativa.
        await cancelPendingWithoutCharge(adminClient, pendingSubscription);
        throw error;
      });

      createdSubscription = {
        preapproval_id: created.preapproval_id,
        status: created.status,
      };

      currentSubscription = await updateSubscriptionAfterPreapproval(
        adminClient,
        {
          subscription: currentSubscription,
          preapproval: created.raw,
          externalReference: external_reference_sub,
        },
      );
    }

    const subscriptionStatus =
      createdSubscription?.status ??
      preapprovalSnapshot?.status ??
      authorizedSubscription?.status ??
      null;
    const subscriptionStartDate =
      currentSubscription.start_date ?? null;

    return jsonOk({
      subscription: {
        preapproval_id: currentSubscription.mp_preapproval_id,
        status: subscriptionStatus,
        start_date: subscriptionStartDate,
        external_reference: external_reference_sub,
      },
      payment: {
        payment_id: payment?.payment_id ?? null,
        status: payment ? payment.status : "skipped",
        status_detail: payment?.status_detail ?? null,
        external_reference: external_reference_pay,
      },
      test_mode: TEST_MODE,
    });
  } catch (error) {
    if (isAppError(error)) {
      // Só código e detalhes do Mercado Pago; nunca dados do cartão.
      safeLog("mercadopago_subscription_app_error", {
        status: error.status,
        code: error.code,
        details: error.details ?? null,
      });
      return jsonError(error.status, { error: toErrorPayload(error) });
    }

    safeLog("mercadopago_subscription_unhandled_error", {
      error: safeError(error),
    });

    return jsonError(500, {
      error: {
        code: "INTERNAL_ERROR",
        message: "Unexpected error",
      },
    });
  }
});
