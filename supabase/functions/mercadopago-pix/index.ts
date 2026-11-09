// Pablife: cobrança por Pix (Mercado Pago). Pagamento único: libera o plano
// por 30 dias, sem renovação automática.
//
// Fluxo: cria a assinatura "pending" (mp_preapproval_id TEMP-PIX-…, que o
// resto do sistema já trata como local), gera o Pix com a mesma
// external_reference do cartão e devolve o QR Code. Quando o Pix é pago, o
// mercadopago-webhook ativa a assinatura (30 dias); se expirar, o webhook a
// cancela. O valor sai do banco, com o desconto de estudante conferido aqui.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info, x-idempotency-key",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const STUDENT_DISCOUNT = 0.1;
const PIX_MINUTES = 30;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors },
  });
}

function fail(status: number, code: string, message: string): Response {
  return json(status, { error: { code, message } });
}

function env(key: string): string {
  const value = Deno.env.get(key);
  if (!value) throw new Error(`Missing env ${key}`);
  return value;
}

async function mp(
  path: string,
  init: { method: string; body?: unknown; idempotencyKey?: string },
): Promise<{ ok: boolean; status: number; data: Record<string, unknown> }> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${env("MERCADOPAGO_ACCESS_TOKEN")}`,
    "Content-Type": "application/json",
  };
  if (init.idempotencyKey) headers["X-Idempotency-Key"] = init.idempotencyKey;
  const response = await fetch(`${env("MERCADOPAGO_API_BASE")}${path}`, {
    method: init.method,
    headers,
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });
  const text = await response.text();
  let data: Record<string, unknown> = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { message: text.slice(0, 300) };
  }
  return { ok: response.ok, status: response.status, data };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return fail(405, "METHOD_NOT_ALLOWED", "Method Not Allowed");
  }

  try {
    const idempotencyKey = req.headers.get("x-idempotency-key")?.trim();
    if (!idempotencyKey) {
      return fail(400, "IDEMPOTENCY_KEY_REQUIRED", "Idempotency key is required");
    }
    let body: { plan_id?: unknown };
    try {
      body = await req.json();
    } catch {
      return fail(400, "INVALID_JSON", "Invalid JSON body");
    }
    const planId = typeof body.plan_id === "string" ? body.plan_id : "";
    if (!planId) return fail(400, "VALIDATION_ERROR", "plan_id is required");

    // Quem pede: sempre pelo token da sessão, nunca pelo corpo.
    const userClient = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data: auth, error: authError } = await userClient.auth.getUser();
    if (authError || !auth?.user?.id) {
      return fail(401, "UNAUTHORIZED", "Invalid token");
    }
    const userId = auth.user.id;
    const admin = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: user } = await admin
      .from("tb_users")
      .select("id, email, full_name, cpf_document, status, deleted_at")
      .eq("id", userId)
      .maybeSingle();
    if (!user || user.status !== "active" || user.deleted_at !== null) {
      return fail(403, "USER_INACTIVE", "User is inactive");
    }

    const { data: plan } = await admin
      .from("tb_subscription_plans")
      .select("id, reason, transaction_amount, currency_id, duration_months, deleted_at")
      .eq("id", planId)
      .maybeSingle();
    if (!plan || plan.deleted_at !== null || plan.transaction_amount === null) {
      return fail(404, "PLAN_NOT_FOUND", "Plan not found");
    }

    // Já tem plano ativo e em dia: não cobra de novo.
    const nowIso = new Date().toISOString();
    const { data: active } = await admin
      .from("tb_user_subscriptions")
      .select("id")
      .eq("user_id", userId)
      .eq("status", "active")
      .gt("end_date", nowIso)
      .limit(1);
    if ((active ?? []).length > 0) {
      return fail(409, "ACTIVE_SUBSCRIPTION", "User already has an active plan");
    }

    // Pix anterior ainda aberto: cancela no Mercado Pago e aqui, para não
    // existirem dois Pix válidos ao mesmo tempo.
    const { data: openPix } = await admin
      .from("tb_user_subscriptions")
      .select("id, mp_preapproval_id")
      .eq("user_id", userId)
      .eq("status", "pending")
      .like("mp_preapproval_id", "TEMP-PIX-%");
    for (const row of openPix ?? []) {
      const paymentId = String(row.mp_preapproval_id).replace("TEMP-PIX-", "");
      if (/^\d+$/.test(paymentId)) {
        const cancel = await mp(`/v1/payments/${paymentId}`, {
          method: "PUT",
          body: { status: "cancelled" },
        });
        // Já pago? Não cancela a assinatura: o webhook vai ativá-la.
        if (!cancel.ok && cancel.data.status === "approved") continue;
      }
      await admin
        .from("tb_user_subscriptions")
        .update({ status: "cancelled", cancelled_at: nowIso })
        .eq("id", row.id)
        .eq("status", "pending");
    }

    const { data: student } = await admin
      .from("tb_student_verifications")
      .select("id")
      .eq("user_id", userId)
      .eq("status", "approved")
      .limit(1);
    const isStudent = (student ?? []).length > 0;
    const fullAmount = Number(plan.transaction_amount);
    const amount = isStudent
      ? Math.round(fullAmount * (1 - STUDENT_DISCOUNT) * 100) / 100
      : fullAmount;

    const { data: uuid, error: uuidError } = await admin.rpc("uuidv7");
    if (uuidError || typeof uuid !== "string") {
      return fail(500, "UUID_GENERATE_FAILED", "Failed to generate id");
    }
    const externalReference = JSON.stringify({
      user_id: userId,
      plan_id: plan.id,
      user_subscription_id: uuid,
    });

    const { error: insertError } = await admin.from("tb_user_subscriptions").insert({
      id: uuid,
      user_id: userId,
      plan_id: plan.id,
      mp_preapproval_id: `TEMP-PIX-${crypto.randomUUID()}`,
      external_reference: externalReference,
      status: "pending",
      has_first_payment: false,
      has_preapproval: false,
      reason: plan.reason,
      frequency: plan.duration_months ?? 1,
      frequency_type: "months",
      transaction_amount: amount,
      currency_id: plan.currency_id ?? "BRL",
    });
    if (insertError) {
      return fail(500, "SUBSCRIPTION_CREATE_FAILED", "Failed to create subscription");
    }

    const expiresAt = new Date(Date.now() + PIX_MINUTES * 60 * 1000);
    const cpf = String(user.cpf_document ?? "").replace(/\D+/g, "");
    const [firstName, ...rest] = String(user.full_name ?? "").trim().split(/\s+/);
    const payment = await mp("/v1/payments", {
      method: "POST",
      idempotencyKey: `${idempotencyKey}-pix`,
      body: {
        transaction_amount: amount,
        description: `Pablife · Plano ${plan.reason}`,
        payment_method_id: "pix",
        date_of_expiration: expiresAt.toISOString().replace("Z", "-00:00"),
        external_reference: externalReference,
        payer: {
          email: user.email,
          ...(firstName ? { first_name: firstName } : {}),
          ...(rest.length ? { last_name: rest.join(" ") } : {}),
          ...(cpf.length === 11
            ? { identification: { type: "CPF", number: cpf } }
            : {}),
        },
      },
    });

    const tx = (payment.data.point_of_interaction as Record<string, unknown> | undefined)
      ?.transaction_data as Record<string, unknown> | undefined;
    const paymentId = payment.data.id;
    if (!payment.ok || !paymentId || !tx?.qr_code) {
      // Nada foi cobrado: encerra a pendência.
      await admin
        .from("tb_user_subscriptions")
        .update({ status: "cancelled", cancelled_at: new Date().toISOString() })
        .eq("id", uuid);
      console.log("[mercadopago-pix] pix_create_failed", {
        status: payment.status,
        message: payment.data.message ?? null,
        cause: payment.data.cause ?? null,
      });
      return fail(502, "PIX_CREATE_FAILED", "Failed to create Pix");
    }

    await admin
      .from("tb_user_subscriptions")
      .update({ mp_preapproval_id: `TEMP-PIX-${paymentId}` })
      .eq("id", uuid);

    await admin.from("tb_subscription_transactions").insert({
      user_subscription_id: uuid,
      mp_payment_id: paymentId,
      external_reference: externalReference,
      status: String(payment.data.status ?? "pending"),
      status_detail: payment.data.status_detail ?? null,
      transaction_amount: amount,
      currency_id: plan.currency_id ?? "BRL",
      installments: 1,
      payment_method_id: "pix",
      payment_type_id: payment.data.payment_type_id ?? "bank_transfer",
      mp_payer_email: user.email,
      mp_date_created: payment.data.date_created ?? null,
      mp_payment_snapshot: payment.data,
    });

    return json(200, {
      user_subscription_id: uuid,
      payment_id: paymentId,
      amount,
      student_discount: isStudent,
      qr_code: tx.qr_code,
      qr_code_base64: tx.qr_code_base64 ?? null,
      expires_at: payment.data.date_of_expiration ?? expiresAt.toISOString(),
    });
  } catch (error) {
    console.log("[mercadopago-pix] unhandled", {
      message: error instanceof Error ? error.message : String(error),
    });
    return fail(500, "INTERNAL_ERROR", "Unexpected error");
  }
});
