import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { serve } from "https://deno.land/std/http/server.ts";
import { config } from "./src/config.ts";
import { jsonResponse, textResponse } from "./src/lib/http.ts";
import {
  extractWebhookEnvelope,
  WebhookEnvelopeError,
  type WebhookEnvelope,
  type WebhookEnvelopeBase,
} from "./src/lib/parse.ts";
import { MercadoPagoService } from "./src/lib/mercadopago_client.ts";
import {
  markWebhookEventProcessed,
  persistWebhookEvent,
  updateWebhookEventProcessingNotes,
} from "./src/lib/persistence.ts";
import { processWebhookEvent } from "./src/lib/processing.ts";
import { getResourceSnapshot, routeTopic } from "./src/lib/router.ts";
import { safeError, safeLog } from "./src/lib/safe_log.ts";
import { generateUuidV7 } from "./src/lib/uuid.ts";
import { verifyMercadoPagoSignature } from "./src/lib/signature.ts";
import type {
  ResourceKind,
  WebhookEventToPersist,
} from "./src/types/persistence.ts";

serve(async (req) => {
  if (req.method !== "POST") {
    return textResponse("Method Not Allowed", 405);
  }

  safeLog("[mercadopago-webhook] webhook_received");

  let envelope: WebhookEnvelope | null = null;
  let envelopeBase: WebhookEnvelopeBase | null = null;
  let envelopeError: "missing_topic_or_type" | null = null;

  try {
    envelope = await extractWebhookEnvelope(req);
    envelopeBase = envelope;
  } catch (error) {
    if (error instanceof WebhookEnvelopeError) {
      envelopeBase = error.envelope;
      envelopeError = error.code;
    } else {
      safeLog("[mercadopago-webhook] envelope_parse_failed", {
        error: safeError(error),
      });
      return jsonResponse({ ok: false, reason: "invalid_envelope" }, 400);
    }
  }

  if (!envelopeBase) {
    return jsonResponse({ ok: false, reason: "invalid_envelope" }, 400);
  }

  const {
    headers,
    rawBodyText,
    bodyJson,
    query,
    topic,
    type,
    action,
    resourceId,
  } = envelopeBase;

  const requestIdHeader = headers["x-request-id"] || null;
  const signatureHeader = headers["x-signature"] || null;
  const requestId = requestIdHeader ?? `missing-${generateUuidV7()}`;
  const receivedAt = new Date().toISOString();
  const rawBody = bodyJson ?? rawBodyText;

  safeLog("[mercadopago-webhook] webhook_received_details", {
    request_id: requestId,
    topic: topic,
    type: type,
    action: action,
    resource_id: resourceId,
  });

  const baseEvent: Omit<
    WebhookEventToPersist,
    "signatureValid" | "sdkSnapshot" | "sdkSnapshotType"
  > = {
    provider: "mercadopago",
    requestId,
    receivedAt,
    eventLabel: topic,
    resourceKind: type,
    resourceAction: action,
    resourceId,
    rawHeaders: headers,
    rawQuery: query,
    rawBody,
  };

  if (envelopeError || !resourceId) {
    const processingNotes = envelopeError ?? "missing_resource_id";
    const event: WebhookEventToPersist = {
      ...baseEvent,
      signatureValid: false,
      sdkSnapshot: null,
      sdkSnapshotType: null,
      processingNotes,
    };

    try {
      await persistWebhookEvent(event);
    } catch (error) {
      safeLog("[mercadopago-webhook] persist_missing_payload_failed", {
        error: safeError(error),
      });
    }

    return jsonResponse({ ok: false, reason: processingNotes }, 400);
  }

  const topicResult = routeTopic(type || topic);
  if (!topicResult) {
    const event: WebhookEventToPersist = {
      ...baseEvent,
      signatureValid: false,
      sdkSnapshot: null,
      sdkSnapshotType: null,
      processingNotes: `unsupported_topic:${type || topic}`,
    };

    try {
      await persistWebhookEvent(event);
    } catch (error) {
      safeLog("[mercadopago-webhook] persist_unsupported_topic_failed", {
        error: safeError(error),
      });
    }

    return jsonResponse({ ok: true, ignored: true }, 200);
  }

  const signatureResult = await verifyMercadoPagoSignature({
    secret: config.mercadopagoWebhookSecret,
    signatureHeader,
    requestId: requestIdHeader,
    id: resourceId,
  });

  if (!signatureResult.valid) {
    const event: WebhookEventToPersist = {
      ...baseEvent,
      resourceKind: type ?? topic,
      signatureValid: false,
      sdkSnapshot: null,
      sdkSnapshotType: null,
      processingNotes: signatureResult.reason ?? "invalid_signature",
    };

    try {
      await persistWebhookEvent(event);
    } catch (error) {
      safeLog("[mercadopago-webhook] persist_invalid_signature_failed", {
        error: safeError(error),
      });
    }

    return jsonResponse({ ok: false, reason: signatureResult.reason }, 401);
  }

  let sdkSnapshot: unknown | null = null;
  let sdkSnapshotType: ResourceKind | null = null;
  let processingNotes: string | null = null;

  const mp = new MercadoPagoService(config.mercadopagoAccessToken, {
    baseUrl: config.mercadopagoApiBase,
  });

  try {
    const snapshotResult = await getResourceSnapshot(
      topicResult,
      resourceId,
      mp,
    );
    sdkSnapshot = snapshotResult.snapshot;
    sdkSnapshotType = snapshotResult.snapshotType;
  } catch (error) {
    processingNotes = `mp_snapshot_fetch_failed:${
      error instanceof Error ? error.message : String(error)
    }`;
    safeLog("[mercadopago-webhook] mp_snapshot_fetch_failed", {
      error: safeError(error),
    });
  }

  const event: WebhookEventToPersist = {
    ...baseEvent,
    resourceKind: type ?? topic,
    signatureValid: true,
    sdkSnapshot,
    sdkSnapshotType,
    processingNotes,
  };

  try {
    await persistWebhookEvent(event);
  } catch (error) {
    safeLog("[mercadopago-webhook] persist_webhook_event_failed", {
      error: safeError(error),
    });
    // Intencional: retornamos 200 para evitar retries quando a assinatura é válida.
  }

  if (!sdkSnapshot || !sdkSnapshotType) {
    return jsonResponse({ ok: true }, 200);
  }

  if (
    sdkSnapshotType !== "payment" &&
    sdkSnapshotType !== "subscription_preapproval"
  ) {
    return jsonResponse({ ok: true }, 200);
  }

  try {
    const processingResult = await processWebhookEvent({
      topic: sdkSnapshotType,
      snapshot: sdkSnapshot,
      requestId,
      mpService: mp,
    });

    if (processingResult.processed) {
      try {
        await markWebhookEventProcessed(
          requestId,
          processingResult.processingNotes ?? null,
        );
      } catch (error) {
        safeLog("[mercadopago-webhook] mark_processed_failed", {
          error: safeError(error),
        });
      }
    } else if (processingResult.processingNotes) {
      try {
        await updateWebhookEventProcessingNotes(
          requestId,
          processingResult.processingNotes,
        );
      } catch (error) {
        safeLog("[mercadopago-webhook] update_processing_notes_failed", {
          error: safeError(error),
        });
      }
    }
  } catch (error) {
    safeLog("[mercadopago-webhook] processing_failed", {
      error: safeError(error),
    });
    try {
      await updateWebhookEventProcessingNotes(
        requestId,
        `processing_failed:${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    } catch (updateError) {
      safeLog("[mercadopago-webhook] update_processing_error_notes_failed", {
        error: safeError(updateError),
      });
    }
  }

  return jsonResponse({ ok: true }, 200);
});
