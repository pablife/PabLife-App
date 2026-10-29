export type WebhookHeaders = Record<string, string>;
export type WebhookQuery = Record<string, string>;
export type WebhookBody = unknown;

export type WebhookPayload = {
  headers: WebhookHeaders;
  query: WebhookQuery;
  body: WebhookBody;
};
