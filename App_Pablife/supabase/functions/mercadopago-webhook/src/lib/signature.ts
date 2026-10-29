export type SignatureParseResult = {
  ts: string | null;
  v1: string | null;
  raw: string | null;
};

export type SignatureVerificationResult = {
  valid: boolean;
  expectedSignature: string | null;
  providedSignature: string | null;
  ts: string | null;
  reason: string | null;
};

export function parseXSignature(
  signatureHeader: string | null,
): SignatureParseResult {
  if (!signatureHeader) {
    return { ts: null, v1: null, raw: null };
  }

  const entries = signatureHeader
    .split(/[,;]/)
    .map((part) => part.trim())
    .filter(Boolean);

  const values: Record<string, string> = {};
  for (const entry of entries) {
    const [key, value] = entry.split("=");
    if (!key || !value) continue;
    values[key.trim()] = value.trim();
  }

  return {
    ts: values.ts ?? null,
    v1: values.v1 ?? null,
    raw: signatureHeader,
  };
}

export function buildManifest(params: {
  id: string;
  requestId: string;
  ts: string;
}): string {
  return `id:${params.id};request-id:${params.requestId};ts:${params.ts};`;
}

function hexToBytes(hex: string): Uint8Array {
  if (hex.length % 2 !== 0) return new Uint8Array();
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = Number.parseInt(hex.slice(i, i + 2), 16);
  }
  return bytes;
}

export function timingSafeEqual(a: string, b: string): boolean {
  const aBytes = hexToBytes(a);
  const bBytes = hexToBytes(b);
  const len = Math.max(aBytes.length, bBytes.length);
  let diff = aBytes.length ^ bBytes.length;

  for (let i = 0; i < len; i += 1) {
    const aByte = aBytes[i] ?? 0;
    const bByte = bBytes[i] ?? 0;
    diff |= aByte ^ bByte;
  }

  return diff === 0;
}

export async function hmacSha256Hex(
  secret: string,
  payload: string,
): Promise<string> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    encoder.encode(payload),
  );
  const bytes = new Uint8Array(signature);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export async function verifyMercadoPagoSignature(params: {
  secret: string;
  signatureHeader: string | null;
  requestId: string | null;
  id: string | null;
}): Promise<SignatureVerificationResult> {
  const { secret, signatureHeader, requestId, id } = params;
  const parsed = parseXSignature(signatureHeader);

  if (!signatureHeader) {
    return {
      valid: false,
      expectedSignature: null,
      providedSignature: null,
      ts: null,
      reason: "missing_x_signature",
    };
  }

  if (!requestId) {
    return {
      valid: false,
      expectedSignature: null,
      providedSignature: parsed.v1,
      ts: parsed.ts,
      reason: "missing_x_request_id",
    };
  }

  if (!id) {
    return {
      valid: false,
      expectedSignature: null,
      providedSignature: parsed.v1,
      ts: parsed.ts,
      reason: "missing_resource_id",
    };
  }

  if (!parsed.ts || !parsed.v1) {
    return {
      valid: false,
      expectedSignature: null,
      providedSignature: parsed.v1,
      ts: parsed.ts,
      reason: "invalid_x_signature_format",
    };
  }

  const manifest = buildManifest({ id, requestId, ts: parsed.ts });
  const expectedSignature = await hmacSha256Hex(secret, manifest);
  const valid = timingSafeEqual(expectedSignature, parsed.v1);

  return {
    valid,
    expectedSignature,
    providedSignature: parsed.v1,
    ts: parsed.ts,
    reason: valid ? null : "signature_mismatch",
  };
}
