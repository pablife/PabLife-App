export type MpWebhookRawEvent = {
  id?: string | number;
  type?: string;
  topic?: string;
  action?: string;
  data?: {
    id?: string | number;
  };
};

export type NormalizedMpEvent = {
  topic: string;
  resource_id: string;
  raw: MpWebhookRawEvent;
};

export function normalizeWebhookEvent(
  _raw: MpWebhookRawEvent,
): NormalizedMpEvent {
  throw new Error("NotImplemented");
}
