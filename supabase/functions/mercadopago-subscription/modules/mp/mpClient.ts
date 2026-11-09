import { AppError } from "../utils/errors.ts";
import type { MpErrorPayload } from "./types.ts";
import { safeLog } from "../utils/safeLog.ts";
import type { Logger } from "../utils/logger.ts";

const DEFAULT_TIMEOUT_MS = 8000;

async function parseJsonOrText(text: string): Promise<unknown> {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function truncate(value: unknown, maxLength = 500): unknown {
  if (typeof value !== "string") {
    return value;
  }
  if (value.length <= maxLength) return value;
  return `${value.slice(0, maxLength)}...`;
}

export class MpClient {
  private accessToken: string;
  private baseUrl: string;
  private timeoutMs: number;
  private logger?: Logger;

  constructor(params: {
    accessToken: string;
    baseUrl: string;
    timeoutMs?: number;
    logger?: Logger;
  }) {
    if (!params.accessToken) {
      throw new AppError(
        500,
        "MISSING_ENV",
        "Missing MERCADOPAGO_ACCESS_TOKEN",
      );
    }
    if (!params.baseUrl) {
      throw new AppError(500, "MISSING_ENV", "Missing MERCADOPAGO_API_BASE");
    }

    this.accessToken = params.accessToken;
    this.baseUrl = params.baseUrl;
    this.timeoutMs = params.timeoutMs ?? DEFAULT_TIMEOUT_MS;
    this.logger = params.logger;
  }

  async request<T>(
    path: string,
    options: {
      method?: string;
      body?: unknown;
      idempotencyKey?: string;
    } = {},
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const method = options.method ?? "GET";
    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.accessToken}`,
      "Content-Type": "application/json",
    };

    if (options.idempotencyKey) {
      headers["X-Idempotency-Key"] = options.idempotencyKey;
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(url, {
        method,
        headers,
        body:
          options.body !== undefined ? JSON.stringify(options.body) : undefined,
        signal: controller.signal,
      });

      const text = await response.text();
      const payload = await parseJsonOrText(text);

      if (!response.ok) {
        const errorPayload = (payload ?? {}) as MpErrorPayload | string;
        const message =
          typeof errorPayload === "string"
            ? errorPayload
            : (errorPayload.message ??
              errorPayload.error ??
              "Mercado Pago error");

        const log = this.logger ?? ((event, meta) => safeLog(event, meta));
        console.log(
          "mercadopago_request_failed",
          options.body !== undefined ? JSON.stringify(options.body) : undefined,
          payload,
        );
        log("mercadopago_request_failed", {
          url,
          status: response.status,
          message,
        });

        throw new AppError(502, "MP_ERROR", "Mercado Pago request failed", {
          status: response.status,
          message: truncate(message),
          response: truncate(errorPayload),
        });
      }

      return payload as T;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      if (error instanceof DOMException && error.name === "AbortError") {
        throw new AppError(502, "MP_TIMEOUT", "Mercado Pago request timed out");
      }

      throw new AppError(
        502,
        "MP_REQUEST_FAILED",
        "Mercado Pago request failed",
      );
    } finally {
      clearTimeout(timeout);
    }
  }
}
