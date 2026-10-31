// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { createEdgeLogger } from "./_shared/edgeLogger.ts";
import {
  cancelPreapproval,
  type MercadoPagoConfig,
} from "./_shared/mercadopagoPreapproval.ts";

type UserRow = {
  id: string;
  status: string;
  deleted_at: string | null;
};

type SubscriptionRow = {
  id: string;
  status: string;
  mp_preapproval_id: string | null;
};

const log = createEdgeLogger("mercadopago-subscription-cancel");

const REQUIRED_ENV_VARS = [
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const;

const missingEnvVars = REQUIRED_ENV_VARS.filter(
  (envVar) => !Deno.env.get(envVar),
);

if (missingEnvVars.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missingEnvVars.join(", ")}`,
  );
}

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const serviceClient = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonOk = (
  payload: Record<string, unknown>,
  status = 200,
): Response =>
  new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });

const jsonError = (
  status: number,
  code: string,
  message: string,
  details?: Record<string, unknown>,
): Response =>
  new Response(
    JSON.stringify({
      error: {
        code,
        message,
        ...(details ? { details } : {}),
      },
    }),
    {
      status,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    },
  );

const successResponse = (code: string, message: string) =>
  jsonOk({ ok: true, code, message });

const errorResponse = (
  status: number,
  code: string,
  message: string,
  details?: Record<string, unknown>,
) => jsonError(status, code, message, details);

const getMercadoPagoConfig = (): MercadoPagoConfig | null => {
  const accessToken = Deno.env.get("MERCADOPAGO_ACCESS_TOKEN");
  const apiBase = Deno.env.get("MERCADOPAGO_API_BASE");
  if (!accessToken || !apiBase) return null;
  return { accessToken, apiBase };
};

// Ids que não existem no Mercado Pago: pendência (TEMP-), cortesia
// (COURTESY-) e cupom (COUPON-).
const LOCAL_PREAPPROVAL_PREFIXES = ["TEMP-", "COURTESY-", "COUPON-"];

const isLocalPreapprovalId = (value: string | null): boolean =>
  !value ||
  LOCAL_PREAPPROVAL_PREFIXES.some((prefix) => value.startsWith(prefix));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse(405, "METHOD_NOT_ALLOWED", "Method Not Allowed");
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse(401, "UNAUTHORIZED", "Token de autenticacao ausente");
  }

  const anonClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: authData, error: authError } = await anonClient.auth.getUser();

  if (authError || !authData?.user) {
    log("Auth validation failed", { error: authError });
    return errorResponse(401, "UNAUTHORIZED", "Token de autenticacao invalido");
  }

  const userId = authData.user.id;
  log("Cancel subscription request received", { userId });

  const { data: userRow, error: userRowError } = await serviceClient
    .from("tb_users")
    .select("id, status, deleted_at")
    .eq("id", userId)
    .maybeSingle<UserRow>();

  if (userRowError) {
    log("Failed to load tb_users record", { error: userRowError });
    return errorResponse(
      500,
      "USER_LOOKUP_FAILED",
      "Nao foi possivel localizar o usuario",
    );
  }

  if (!userRow) {
    return errorResponse(404, "USER_NOT_FOUND", "Usuario nao encontrado");
  }

  if (userRow.deleted_at || userRow.status === "deleted") {
    return successResponse(
      "SUBSCRIPTION_ALREADY_CANCELLED",
      "Assinatura ja cancelada",
    );
  }

  const { data: subscriptionRows, error: subscriptionError } =
    await serviceClient
      .from("tb_user_subscriptions")
      .select("id, status, mp_preapproval_id")
      .eq("user_id", userId)
      .in("status", ["active", "pending"]);

  if (subscriptionError) {
    log("Failed to load user subscriptions", { error: subscriptionError });
    return errorResponse(
      500,
      "SUBSCRIPTION_LOOKUP_FAILED",
      "Nao foi possivel buscar assinaturas",
    );
  }

  const subscriptions = subscriptionRows ?? [];
  const activeSubscriptions = subscriptions.filter(
    (subscription) => subscription.status === "active",
  );
  const pendingSubscriptions = subscriptions.filter(
    (subscription) => subscription.status === "pending",
  );

  if (activeSubscriptions.length === 0 && pendingSubscriptions.length === 0) {
    return successResponse(
      "NO_ACTIVE_SUBSCRIPTION",
      "Nenhuma assinatura ativa para cancelar",
    );
  }

  if (activeSubscriptions.length === 0 && pendingSubscriptions.length > 0) {
    return errorResponse(
      409,
      "SUBSCRIPTION_PENDING",
      "Sua assinatura ainda nao pode ser cancelada. Tente novamente mais tarde",
    );
  }

  if (activeSubscriptions.length > 0 && pendingSubscriptions.length > 0) {
    return errorResponse(
      409,
      "SUBSCRIPTION_UPGRADE_IN_PROGRESS",
      "Existe um upgrade em andamento. Nao e possivel cancelar no momento",
    );
  }

  // Cortesias e cupons (e pendências TEMP-) não existem no Mercado Pago: são
  // só encerradas aqui. No máximo uma assinatura ativa é do Mercado Pago.
  const mpSubscriptions = activeSubscriptions.filter(
    (subscription) => !isLocalPreapprovalId(subscription.mp_preapproval_id),
  );

  if (mpSubscriptions.length > 1) {
    return errorResponse(
      409,
      "MULTIPLE_ACTIVE_SUBSCRIPTIONS",
      "Nao foi possivel identificar a assinatura ativa",
    );
  }

  const mpPreapprovalId = mpSubscriptions[0]?.mp_preapproval_id ?? null;

  if (mpPreapprovalId) {
    const mercadopagoConfig = getMercadoPagoConfig();
    if (!mercadopagoConfig) {
      log("Mercado Pago config missing for cancellation", { userId });
      return errorResponse(
        500,
        "MERCADOPAGO_CONFIG_MISSING",
        "Nao foi possivel cancelar a assinatura no momento",
      );
    }

    try {
      await cancelPreapproval({
        config: mercadopagoConfig,
        preapprovalId: mpPreapprovalId,
        log,
      });
    } catch (error) {
      log("Mercado Pago cancel failed", { error, mpPreapprovalId });
      return errorResponse(
        502,
        "MERCADOPAGO_CANCEL_FAILED",
        "Nao foi possivel cancelar a assinatura no momento",
      );
    }
  }

  const now = new Date().toISOString();
  const { error: updateError } = await serviceClient
    .from("tb_user_subscriptions")
    .update({
      status: "cancelled",
      cancelled_at: now,
      updated_at: now,
    })
    .in(
      "id",
      activeSubscriptions.map((subscription) => subscription.id),
    );

  if (updateError) {
    log("Failed to update cancelled subscription", { error: updateError });
    return errorResponse(
      500,
      "SUBSCRIPTION_CANCEL_UPDATE_FAILED",
      "Nao foi possivel atualizar o cancelamento da assinatura",
    );
  }

  return successResponse(
    "SUBSCRIPTION_CANCELLED",
    "Assinatura cancelada com sucesso",
  );
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/mercadopago-subscription-cancel' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
