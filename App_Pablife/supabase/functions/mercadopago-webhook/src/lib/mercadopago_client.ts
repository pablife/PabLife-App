import type {
  JsonObject,
  JsonValue,
  MerchantOrderResponseType,
  OrderResponseType,
  PaymentResponseType,
  PreapprovalResponseType,
} from "../types/mercadopago.ts";
import { safeLog } from "./safe_log.ts";

type LogLevel = "debug" | "info" | "warn" | "error";

type Logger = (level: LogLevel, message: string, meta?: JsonObject) => void;

type MercadoPagoErrorResponse = {
  message?: string;
  error?: string;
  status?: number;
  cause?: JsonValue;
};

function defaultLogger(level: LogLevel, message: string, meta?: JsonObject) {
  const payload = meta ? { message, level, ...meta } : { message, level };
  safeLog("[mercadopago-webhook] mercadopago_client", payload);
}

function truncate(text: string, maxLength = 500): string {
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength)}...`;
}

async function parseJsonOrText(text: string): Promise<unknown> {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

export class MercadoPagoService {
  private accessToken: string;
  private baseUrl: string;
  private logger: Logger;
  private fetcher: typeof fetch;
  private timeoutMs: number;

  constructor(
    accessToken: string,
    options?: {
      baseUrl: string;
      logger?: Logger;
      fetcher?: typeof fetch;
      timeoutMs?: number;
    },
  ) {
    this.accessToken = accessToken;
    this.baseUrl = options?.baseUrl ?? "";
    if (!this.baseUrl || !this.baseUrl.trim()) {
      throw new Error("Missing required Mercado Pago base URL");
    }
    this.logger = options?.logger ?? defaultLogger;
    this.fetcher = options?.fetcher ?? fetch;
    this.timeoutMs = options?.timeoutMs ?? 8000;
  }

  async getPayment(id: string): Promise<PaymentResponseType> {
    return await this.request<PaymentResponseType>(`/v1/payments/${id}`);
  }

  async getMerchantOrder(id: string): Promise<MerchantOrderResponseType> {
    return await this.request<MerchantOrderResponseType>(
      `/merchant_orders/${id}`,
    );
  }

  async getOrder(id: string): Promise<OrderResponseType> {
    return await this.request<OrderResponseType>(`/v1/orders/${id}`);
  }

  async getPreapproval(id: string): Promise<PreapprovalResponseType> {
    return await this.request<PreapprovalResponseType>(`/preapproval/${id}`);
  }

  async searchAuthorizedPayments(paymentId: string): Promise<JsonObject> {
    const encoded = encodeURIComponent(paymentId);
    return await this.request<JsonObject>(
      `/authorized_payments/search?payment_id=${encoded}`,
    );
  }

  async updatePreapprovalStatus(
    id: string,
    status: "cancelled",
  ): Promise<PreapprovalResponseType> {
    return await this.request<PreapprovalResponseType>(`/preapproval/${id}`, {
      method: "PUT",
      body: { status },
    });
  }

  private async request<T>(
    path: string,
    options?: { method?: string; body?: JsonValue },
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const startedAt = Date.now();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
    const method = options?.method ?? "GET";
    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.accessToken}`,
      Accept: "application/json",
    };
    let body: string | undefined;

    if (options?.body !== undefined && method !== "GET") {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(options.body);
    }

    try {
      const response = await this.fetcher(url, {
        method,
        headers,
        body,
        signal: controller.signal,
      });

      const durationMs = Date.now() - startedAt;
      const text = await response.text();
      const payload = await parseJsonOrText(text);

      this.logger("info", "Mercado Pago request completed", {
        url,
        status: response.status,
        duration_ms: durationMs,
      });

      if (!response.ok) {
        const errorPayload = (payload ?? {}) as
          | MercadoPagoErrorResponse
          | string;
        const errorMessage = typeof errorPayload === "string"
          ? errorPayload
          : (errorPayload.message ??
            errorPayload.error ??
            "Mercado Pago request failed");

        this.logger("error", "Mercado Pago request failed", {
          url,
          status: response.status,
          duration_ms: durationMs,
          error: errorMessage,
          response: typeof errorPayload === "string"
            ? truncate(errorPayload)
            : errorPayload,
        });

        throw new Error(
          `Mercado Pago API error ${response.status}: ${errorMessage}`,
        );
      }

      return payload as T;
    } catch (error) {
      const durationMs = Date.now() - startedAt;
      if (error instanceof DOMException && error.name === "AbortError") {
        this.logger("error", "Mercado Pago request timed out", {
          url,
          duration_ms: durationMs,
        });
        throw new Error("Mercado Pago API request timed out");
      }
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }
}

export type {
  MerchantOrderResponseType,
  OrderResponseType,
  PaymentResponseType,
  PreapprovalResponseType,
};
