import { AppError } from "./errors.ts";

export function requireIdempotencyKey(req: Request): string {
  const existing =
    req.headers.get("X-Idempotency-Key") ??
    req.headers.get("x-idempotency-key");

  if (existing && existing.trim().length > 0) {
    return existing.trim();
  }

  throw new AppError(
    400,
    "IDEMPOTENCY_KEY_REQUIRED",
    "Idempotency key is required",
  );
}

export function deriveIdempotencyKeys(
  requestId: string,
  subscriptionId: string,
): {
  baseKey: string;
  payKey: string;
  subKey: string;
} {
  const baseKey = `${requestId}-${subscriptionId}`;
  return {
    baseKey,
    payKey: `${baseKey}-pay`,
    subKey: `${subscriptionId}-sub`,
  };
}
