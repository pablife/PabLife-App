export type ResourceKind =
  | "payment"
  | "merchant_order"
  | "order"
  | "subscription_preapproval"
  | "unknown";

export type WebhookEventToPersist = {
  provider: "mercadopago";
  requestId: string;
  signatureValid: boolean;
  receivedAt: string;
  eventLabel: string | null;
  resourceKind: string;
  resourceAction: string;
  resourceId: string | null;
  rawHeaders: Record<string, string>;
  rawQuery: Record<string, string>;
  rawBody: unknown;
  sdkSnapshot: unknown | null;
  sdkSnapshotType: ResourceKind | null;
  processingNotes?: string | null;
};
