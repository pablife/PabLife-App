import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { log } from "./src/_shared/logger.ts";
import { jsonResponse } from "./src/_shared/response.ts";
import { generateUuidV7 } from "./src/_shared/uuid.ts";
import {
  cancelPreapproval,
  isTempPreapprovalId,
  type MercadoPagoConfig,
} from "./src/_shared/mercadopago.ts";

type UserRole = "user" | "professional";

type UserRow = {
  id: string;
  role: string;
  status: string;
  deleted_at: string | null;
  email: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

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
const mercadopagoAccessToken = Deno.env.get("MERCADOPAGO_ACCESS_TOKEN");
const mercadopagoApiBase = Deno.env.get("MERCADOPAGO_API_BASE");

const serviceClient = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const mercadopagoConfig: MercadoPagoConfig | null =
  mercadopagoAccessToken && mercadopagoApiBase
    ? { accessToken: mercadopagoAccessToken, apiBase: mercadopagoApiBase }
    : null;

const ALLOWED_ROLES: ReadonlySet<UserRole> = new Set(["user", "professional"]);

const HARD_DELETE_ALLOWLIST = new Set(["tb_favorite_mentorships"]);

const errorResponse = (status: number, code: string, message: string) =>
  jsonResponse(
    {
      success: false,
      code,
      message,
    },
    status,
    corsHeaders,
  );

const successResponse = (message: string, data?: Record<string, unknown>) =>
  jsonResponse(
    {
      success: true,
      code: "DELETE_ACCOUNT_SUCCESS",
      message,
      data,
    },
    200,
    corsHeaders,
  );

const toNumericString = (value: string, length: number) => {
  const digits = value.replace(/\D/g, "");
  if (digits.length >= length) {
    return digits.slice(0, length);
  }
  return digits.padEnd(length, "0");
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse(405, "METHOD_NOT_ALLOWED", "Metodo nao permitido");
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
  const accessToken = authHeader.replace(/^Bearer\s+/i, "").trim();

  log("Delete account request received", { userId });

  const { data: userRow, error: userRowError } = await serviceClient
    .from("tb_users")
    .select("id, role, status, deleted_at, email")
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

  if (!ALLOWED_ROLES.has(userRow.role as UserRole)) {
    return errorResponse(
      403,
      "ROLE_NOT_ALLOWED",
      "Tipo de usuario nao permitido para esta operacao",
    );
  }

  const now = new Date().toISOString();

  try {
    const { data: activeSubscriptions, error: subscriptionLookupError } =
      await serviceClient
        .from("tb_user_subscriptions")
        .select("id, plan_id, status, mp_preapproval_id")
        .eq("user_id", userId)
        .in("status", ["active", "pending"]);

    if (subscriptionLookupError) {
      log("Failed to load user subscriptions", {
        error: subscriptionLookupError,
      });
      return errorResponse(
        500,
        "SUBSCRIPTION_LOOKUP_FAILED",
        "Nao foi possivel processar assinaturas",
      );
    }

    const subscriptions = activeSubscriptions ?? [];

    if (subscriptions.length > 0 && !mercadopagoConfig) {
      log("Mercado Pago config missing for cancellation", {
        subscriptions: subscriptions.length,
      });
    }

    const cancelledSubscriptionIds = new Set<string>();

    if (subscriptions.length > 0 && mercadopagoConfig) {
      for (const subscription of subscriptions) {
        if (
          subscription.mp_preapproval_id &&
          !isTempPreapprovalId(subscription.mp_preapproval_id)
        ) {
          try {
            await cancelPreapproval({
              config: mercadopagoConfig,
              preapprovalId: subscription.mp_preapproval_id,
            });
            cancelledSubscriptionIds.add(subscription.id);
          } catch (error) {
            log("Failed to cancel Mercado Pago preapproval", {
              error,
              preapprovalId: subscription.mp_preapproval_id,
            });
          }
        } else {
          log("Skipping Mercado Pago cancel due to TEMP or missing id", {
            subscriptionId: subscription.id,
          });
        }
      }
    }

    if (cancelledSubscriptionIds.size > 0) {
      const { error: cancelUpdateError } = await serviceClient
        .from("tb_user_subscriptions")
        .update({
          status: "cancelled",
          cancelled_at: now,
          updated_at: now,
        })
        .in("id", Array.from(cancelledSubscriptionIds));

      if (cancelUpdateError) {
        log("Failed to update cancelled subscriptions", {
          error: cancelUpdateError,
        });
        return errorResponse(
          500,
          "SUBSCRIPTION_CANCEL_UPDATE_FAILED",
          "Nao foi possivel atualizar o cancelamento das assinaturas",
        );
      }
    }

    const { error: userSoftDeleteError } = await serviceClient
      .from("tb_users")
      .update({
        status: "deleted",
        deleted_at: now,
        updated_at: now,
      })
      .eq("id", userId);

    if (userSoftDeleteError) {
      log("Failed to soft delete tb_users", { error: userSoftDeleteError });
      return errorResponse(
        500,
        "USER_SOFT_DELETE_FAILED",
        "Nao foi possivel finalizar a exclusao",
      );
    }

    const userUuid = await generateUuidV7(serviceClient);
    const subscriptionUuid = await generateUuidV7(serviceClient);
    const professionalUuid = await generateUuidV7(serviceClient);

    const deletedEmail = `deleted+${userUuid}@example.invalid`;
    const deletedCpf = toNumericString(userUuid, 11);
    const deletedExternalReference = `deleted_${subscriptionUuid}`;
    const deletedProfessionalDocumentUrl = `https://example.invalid/deleted/${professionalUuid}`;

    const { data: professionalRow, error: professionalError } =
      await serviceClient
        .from("tb_professionals")
        .select("id")
        .eq("user_id", userId)
        .maybeSingle<{ id: string }>();

    if (professionalError) {
      log("Failed to load tb_professionals record", {
        error: professionalError,
      });
      return errorResponse(
        500,
        "PROFESSIONAL_LOOKUP_FAILED",
        "Nao foi possivel localizar o profissional",
      );
    }

    const professionalId = professionalRow?.id ?? null;

    const { data: activityRows, error: activitySelectError } =
      await serviceClient
        .from("tb_activities")
        .select("activity_recurrence_rule_id")
        .eq("user_id", userId);

    if (activitySelectError) {
      log("Failed to load activities", { error: activitySelectError });
      return errorResponse(
        500,
        "ACTIVITY_LOOKUP_FAILED",
        "Nao foi possivel processar as atividades",
      );
    }

    const activityRuleIds = Array.from(
      new Set(
        (activityRows ?? [])
          .map((row) => row.activity_recurrence_rule_id as string | null)
          .filter((value): value is string => Boolean(value)),
      ),
    );

    const { error: activityUpdateError } = await serviceClient
      .from("tb_activities")
      .update({
        name: "Atividade removida",
        description: null,
        steps: [],
        due_at: null,
        timezone: "UTC",
        updated_at: now,
      })
      .eq("user_id", userId);

    if (activityUpdateError) {
      log("Failed to anonymize activities", { error: activityUpdateError });
      return errorResponse(
        500,
        "ACTIVITY_ANONYMIZE_FAILED",
        "Nao foi possivel anonimizar as atividades",
      );
    }

    if (activityRuleIds.length > 0) {
      const { error: recurrenceUpdateError } = await serviceClient
        .from("tb_activity_recurrence_rules")
        .update({
          timezone: "UTC",
          rrule_raw: null,
          updated_at: now,
        })
        .in("id", activityRuleIds);

      if (recurrenceUpdateError) {
        log("Failed to anonymize activity recurrence rules", {
          error: recurrenceUpdateError,
        });
        return errorResponse(
          500,
          "ACTIVITY_RECURRENCE_ANONYMIZE_FAILED",
          "Nao foi possivel anonimizar recorrencias",
        );
      }
    }

    const { data: patientRows, error: patientError } = await serviceClient
      .from("tb_patients")
      .select("id")
      .eq("user_id", userId);

    if (patientError) {
      log("Failed to load patient records", { error: patientError });
      return errorResponse(
        500,
        "PATIENT_LOOKUP_FAILED",
        "Nao foi possivel processar os pacientes",
      );
    }

    const patientIds = (patientRows ?? []).map((row) => row.id as string);

    if (patientIds.length > 0) {
      const { error: patientRecordsError } = await serviceClient
        .from("tb_patient_records")
        .update({
          title: "Registro removido",
          description: "Conteudo removido",
          updated_at: now,
        })
        .in("patient_id", patientIds);

      if (patientRecordsError) {
        log("Failed to anonymize patient records", {
          error: patientRecordsError,
        });
        return errorResponse(
          500,
          "PATIENT_RECORDS_ANONYMIZE_FAILED",
          "Nao foi possivel anonimizar registros clinicos",
        );
      }
    }

    const { error: notificationError } = await serviceClient
      .from("tb_notifications")
      .update({
        title: "Notificacao removida",
        message: "Conteudo removido",
        metadata: {},
        updated_at: now,
      })
      .eq("user_id", userId);

    if (notificationError) {
      log("Failed to anonymize notifications", { error: notificationError });
      return errorResponse(
        500,
        "NOTIFICATION_ANONYMIZE_FAILED",
        "Nao foi possivel anonimizar notificacoes",
      );
    }

    const { data: subscriptionRows, error: subscriptionError } =
      await serviceClient
        .from("tb_user_subscriptions")
        .select("id")
        .eq("user_id", userId);

    if (subscriptionError) {
      log("Failed to load subscriptions", { error: subscriptionError });
      return errorResponse(
        500,
        "SUBSCRIPTION_LOOKUP_FAILED",
        "Nao foi possivel processar assinaturas",
      );
    }

    const subscriptionIds = (subscriptionRows ?? []).map(
      (row) => row.id as string,
    );

    const { error: subscriptionUpdateError } = await serviceClient
      .from("tb_user_subscriptions")
      .update({
        mp_payer_id: null,
        mp_payer_email: null,
        external_reference: deletedExternalReference,
        updated_at: now,
      })
      .eq("user_id", userId);

    if (subscriptionUpdateError) {
      log("Failed to anonymize subscriptions", {
        error: subscriptionUpdateError,
      });
      return errorResponse(
        500,
        "SUBSCRIPTION_ANONYMIZE_FAILED",
        "Nao foi possivel anonimizar assinaturas",
      );
    }

    if (subscriptionIds.length > 0) {
      const { error: transactionUpdateError } = await serviceClient
        .from("tb_subscription_transactions")
        .update({
          mp_payer_id: null,
          mp_payer_email: null,
          external_reference: null,
          mp_payment_snapshot: {},
          updated_at: now,
        })
        .in("user_subscription_id", subscriptionIds);

      if (transactionUpdateError) {
        log("Failed to anonymize subscription transactions", {
          error: transactionUpdateError,
        });
        return errorResponse(
          500,
          "SUBSCRIPTION_TRANSACTIONS_ANONYMIZE_FAILED",
          "Nao foi possivel anonimizar transacoes",
        );
      }
    }

    if (professionalId) {
      const { data: appointmentTimeRows, error: appointmentTimeError } =
        await serviceClient
          .from("tb_appointment_times")
          .select("appointment_recurrence_rule_id")
          .eq("professional_id", professionalId);

      if (appointmentTimeError) {
        log("Failed to load appointment times", {
          error: appointmentTimeError,
        });
        return errorResponse(
          500,
          "APPOINTMENT_TIMES_LOOKUP_FAILED",
          "Nao foi possivel processar horarios",
        );
      }

      const appointmentRuleIds = Array.from(
        new Set(
          (appointmentTimeRows ?? [])
            .map((row) => row.appointment_recurrence_rule_id as string | null)
            .filter((value): value is string => Boolean(value)),
        ),
      );

      const { error: appointmentTimeUpdateError } = await serviceClient
        .from("tb_appointment_times")
        .update({
          deleted_at: now,
          updated_at: now,
        })
        .eq("professional_id", professionalId);

      if (appointmentTimeUpdateError) {
        log("Failed to anonymize appointment times", {
          error: appointmentTimeUpdateError,
        });
        return errorResponse(
          500,
          "APPOINTMENT_TIMES_ANONYMIZE_FAILED",
          "Nao foi possivel anonimizar horarios",
        );
      }

      if (appointmentRuleIds.length > 0) {
        const { error: appointmentRuleUpdateError } = await serviceClient
          .from("tb_appointment_recurrence_rules")
          .update({
            timezone: "UTC",
            rrule_raw: null,
            updated_at: now,
          })
          .in("id", appointmentRuleIds);

        if (appointmentRuleUpdateError) {
          log("Failed to anonymize appointment recurrence rules", {
            error: appointmentRuleUpdateError,
          });
          return errorResponse(
            500,
            "APPOINTMENT_RECURRENCE_ANONYMIZE_FAILED",
            "Nao foi possivel anonimizar recorrencias",
          );
        }
      }

      const { error: professionalAnonymizeError } = await serviceClient
        .from("tb_professionals")
        .update({
          description: null,
          validation_document_url: deletedProfessionalDocumentUrl,
          updated_at: now,
        })
        .eq("id", professionalId);

      if (professionalAnonymizeError) {
        log("Failed to anonymize professional profile", {
          error: professionalAnonymizeError,
        });
        return errorResponse(
          500,
          "PROFESSIONAL_ANONYMIZE_FAILED",
          "Nao foi possivel anonimizar o profissional",
        );
      }
    }

    if (HARD_DELETE_ALLOWLIST.has("tb_favorite_mentorships")) {
      log(
        "Hard delete tb_favorite_mentorships: preferencias pessoais sem impacto operacional; allowlist",
      );
      const { error: favoritesDeleteError } = await serviceClient
        .from("tb_favorite_mentorships")
        .delete()
        .eq("user_id", userId);

      if (favoritesDeleteError) {
        log("Failed to hard delete favorites", {
          error: favoritesDeleteError,
        });
        return errorResponse(
          500,
          "FAVORITES_DELETE_FAILED",
          "Nao foi possivel remover favoritos",
        );
      }
    }

    const { error: userAnonymizeError } = await serviceClient
      .from("tb_users")
      .update({
        full_name: "Usuario removido",
        email: deletedEmail,
        phone: "+00000000000",
        cpf_document: deletedCpf,
        image_url: null,
        terms_accepted: false,
        one_signal_user_id: null,
        updated_at: now,
      })
      .eq("id", userId);

    if (userAnonymizeError) {
      log("Failed to anonymize user data", { error: userAnonymizeError });
      return errorResponse(
        500,
        "USER_ANONYMIZE_FAILED",
        "Nao foi possivel anonimizar dados do usuario",
      );
    }

    const { error: signOutError } = await serviceClient.auth.admin.signOut(
      accessToken,
      "global",
    );

    if (signOutError) {
      log("Failed to revoke user sessions", { error: signOutError });
    }

    if (professionalId) {
      const { error: professionalSoftDeleteError } = await serviceClient
        .from("tb_professionals")
        .update({
          deleted_at: now,
          updated_at: now,
        })
        .eq("id", professionalId);

      if (professionalSoftDeleteError) {
        log("Failed to soft delete tb_professionals", {
          error: professionalSoftDeleteError,
        });
        return errorResponse(
          500,
          "PROFESSIONAL_SOFT_DELETE_FAILED",
          "Nao foi possivel finalizar a exclusao",
        );
      }
    }

    const { error: authSoftDeleteError } =
      await serviceClient.auth.admin.deleteUser(userId, true);

    if (authSoftDeleteError) {
      log("Failed to soft delete auth user", { error: authSoftDeleteError });
    } else {
      log("Auth user soft deleted", { userId });
    }

    return successResponse("Conta excluida com sucesso", {
      userId,
      sessionsRevoked: !signOutError,
      authSoftDeleted: !authSoftDeleteError,
    });
  } catch (error) {
    log("Unexpected error while deleting account", { error });
    return errorResponse(
      500,
      "DELETE_ACCOUNT_FAILED",
      "Nao foi possivel concluir a exclusao da conta",
    );
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/delete-account' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
