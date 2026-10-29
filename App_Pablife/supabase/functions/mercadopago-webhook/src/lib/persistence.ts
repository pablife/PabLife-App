import { config } from "../config.ts";
import type { WebhookEventToPersist } from "../types/persistence.ts";
import { buildWebhookEventPayload } from "./persistence_payload.ts";
import { safeLog } from "./safe_log.ts";
import { getSupabaseClient } from "./supabase_client.ts";

type InsertPayload = ReturnType<typeof buildWebhookEventPayload>;

function isDuplicateRequestId(error: unknown): boolean {
  if (!error || typeof error !== "object") return false;
  const payload = error as {
    code?: string;
    message?: string;
    details?: string;
  } & Record<string, unknown>;
  if (payload.code === "23505") return true;
  const message = `${payload.message ?? ""} ${payload.details ?? ""}`
    .toLowerCase();
  return message.includes("request_id") && message.includes("duplicate");
}

export async function persistWebhookEvent(
  event: WebhookEventToPersist,
): Promise<void> {
  if (!config.enablePersistence) {
    safeLog("[mercadopago-webhook] persistence_disabled_skip_insert");
    return;
  }

  const payload: InsertPayload = buildWebhookEventPayload(event);

  const client = getSupabaseClient();
  const { error } = await client
    .from("tb_mercadopago_webhook_events")
    .insert(payload);

  if (error) {
    if (isDuplicateRequestId(error)) {
      safeLog("[mercadopago-webhook] duplicate_request_id_skip_insert");
      return;
    }
    throw error;
  }
}

export async function markWebhookEventProcessed(
  requestId: string,
  processingNotes?: string | null,
): Promise<void> {
  if (!config.enablePersistence) return;

  const client = getSupabaseClient();
  const payload: Record<string, unknown> = { processed: true };
  if (processingNotes) payload.processing_notes = processingNotes;

  const { error } = await client
    .from("tb_mercadopago_webhook_events")
    .update(payload)
    .eq("request_id", requestId);

  if (error) throw error;
}

export async function updateWebhookEventProcessingNotes(
  requestId: string,
  processingNotes: string,
): Promise<void> {
  if (!config.enablePersistence) return;

  const client = getSupabaseClient();
  const { error } = await client
    .from("tb_mercadopago_webhook_events")
    .update({ processing_notes: processingNotes })
    .eq("request_id", requestId);

  if (error) throw error;
}
