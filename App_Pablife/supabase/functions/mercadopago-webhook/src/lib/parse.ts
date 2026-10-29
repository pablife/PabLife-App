export type WebhookEnvelopeBase = {
  url: URL;
  headers: Record<string, string>;
  rawBodyText: string;
  bodyJson: unknown | null;
  query: Record<string, string>;
  topic: string | null;
  type: string | null;
  action: string | null;
  resourceId: string | null;
};

export type WebhookEnvelope = Omit<
  WebhookEnvelopeBase,
  "topic" | "type" | "topicOrType" | "action"
> & {
  topic: string;
  type: string;
  topicOrType: string;
  action: string;
};

export class WebhookEnvelopeError extends Error {
  code: "missing_topic_or_type";
  envelope: WebhookEnvelopeBase;

  constructor(code: "missing_topic_or_type", envelope: WebhookEnvelopeBase) {
    super(code);
    this.code = code;
    this.envelope = envelope;
  }
}

const HEADER_KEYS = [
  "x-signature",
  "x-request-id",
  "content-type",
  "user-agent",
] as const;

type RecordValue = Record<string, string>;

function collectHeaders(req: Request): RecordValue {
  const headers: RecordValue = {};
  for (const [key, value] of req.headers.entries()) {
    headers[key.toLowerCase()] = value;
  }
  for (const key of HEADER_KEYS) {
    if (!(key in headers)) headers[key] = "";
  }
  return headers;
}

function collectQuery(url: URL): RecordValue {
  const query: RecordValue = {};
  for (const [key, value] of url.searchParams.entries()) {
    query[key] = value;
  }
  return query;
}

function safeJsonParse(text: string): unknown | null {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function toStringValue(value: unknown): string | null {
  if (typeof value === "string") return value;
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  return null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function extractIdFromBody(bodyJson: unknown | null): string | null {
  if (!isRecord(bodyJson)) return null;
  const data = bodyJson["data"];
  const idFromData = isRecord(data) ? toStringValue(data["id"]) : null;
  if (idFromData) return idFromData;
  return toStringValue(bodyJson["id"]);
}

function extractTypeFromBody(
  bodyJson: unknown | null,
  key = "type",
): string | null {
  if (!isRecord(bodyJson)) return null;
  return toStringValue(bodyJson[key]);
}

export async function extractWebhookEnvelope(
  req: Request,
): Promise<WebhookEnvelope> {
  const url = new URL(req.url);
  const headers = collectHeaders(req);
  const rawBodyText = await req.text();
  const bodyJson = safeJsonParse(rawBodyText);
  const query = collectQuery(url);

  const topic = toStringValue(query["topic"]) ?? toStringValue(query["type"]);
  const type = extractTypeFromBody(bodyJson, "type");
  const action = extractTypeFromBody(bodyJson, "action");

  const resourceId =
    toStringValue(query["data.id"]) ??
    toStringValue(query["id"]) ??
    extractIdFromBody(bodyJson);

  const topicOrType = topic ?? type;

  const envelope: WebhookEnvelopeBase = {
    url,
    headers,
    rawBodyText,
    bodyJson,
    query,
    action,
    resourceId,
    topic: topic,
    type: type,
  };

  if (!topicOrType) {
    throw new WebhookEnvelopeError("missing_topic_or_type", envelope);
  }

  const resolvedTopic = topic ?? topicOrType;
  const resolvedType = type ?? topicOrType;

  return {
    ...envelope,
    action,
    topic: resolvedTopic,
    type: resolvedType,
    topicOrType,
  } as WebhookEnvelope;
}

export { collectHeaders, safeJsonParse };
