type ExternalReferencePayload = {
  user_id: string;
  plan_id: string;
  user_subscription_id: string;
};

export type ParsedExternalReference = {
  userId: string;
  planId: string;
  userSubscriptionId: string;
  rawValue: string;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function toStringValue(value: unknown): string | null {
  if (typeof value === "string") return value;
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  return null;
}

export function parseExternalReference(
  rawValue: unknown,
): ParsedExternalReference | null {
  if (typeof rawValue !== "string") return null;
  if (!rawValue.trim()) return null;

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawValue);
  } catch {
    return null;
  }

  if (!isRecord(parsed)) return null;

  const userId = toStringValue(parsed.user_id);
  const planId = toStringValue(parsed.plan_id);
  const userSubscriptionId = toStringValue(parsed.user_subscription_id);

  if (!userId || !planId || !userSubscriptionId) return null;

  return { userId, planId, userSubscriptionId, rawValue };
}

export function buildExternalReference(params: {
  userId: string;
  planId: string;
  userSubscriptionId: string;
}): string {
  const payload: ExternalReferencePayload = {
    user_id: params.userId,
    plan_id: params.planId,
    user_subscription_id: params.userSubscriptionId,
  };

  return JSON.stringify(payload);
}
