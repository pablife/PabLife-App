import type { WebhookEventToPersist } from "../types/persistence.ts";

export function buildWebhookEventPayload(event: WebhookEventToPersist) {
  return {
    provider: event.provider,
    request_id: event.requestId,
    signature_valid: event.signatureValid,
    event_label: event.eventLabel,
    resource_kind: event.resourceKind,
    resource_action: event.resourceAction,
    resource_id: event.resourceId,
    received_at: event.receivedAt,
    raw_headers: event.rawHeaders,
    raw_query: event.rawQuery,
    raw_body: event.rawBody,
    sdk_snapshot_type: event.sdkSnapshotType,
    sdk_snapshot: event.sdkSnapshot,
    processing_notes: event.processingNotes ?? null,
  };
}
