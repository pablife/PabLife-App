const SENSITIVE_KEY_PATTERN =
  /(authorization|token|access|secret|card|password)/i;

function sanitize(value: unknown): unknown {
  if (!value || typeof value !== "object") {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => sanitize(item));
  }

  const record = value as Record<string, unknown>;
  const sanitized: Record<string, unknown> = {};

  for (const [key, fieldValue] of Object.entries(record)) {
    if (SENSITIVE_KEY_PATTERN.test(key)) {
      sanitized[key] = "[redacted]";
    } else {
      sanitized[key] = sanitize(fieldValue);
    }
  }

  return sanitized;
}

export function safeLog(message: string, meta?: Record<string, unknown>) {
  if (meta) {
    console.log(message, sanitize(meta));
  } else {
    console.log(message);
  }
}

export function safeError(error: unknown): Record<string, unknown> {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
    };
  }

  return { message: String(error) };
}
