import { AppError } from "../utils/errors.ts";
import { getDocumentType } from "../utils/documents.ts";

const DEFAULT_TIMEOUT_MS = 8000;

export type CardInput = {
  name: string;
  cpfOrCnpj: string;
  cardNumber: string;
  expirationMonth: number;
  expirationYear: number;
  securityCode: string;
};

type CardTokenResponse = {
  id?: string;
  payment_method_id?: string;
  status?: number;
  message?: string;
  error?: string;
  cause?: unknown;
};

type PaymentMethodSearchResponse = {
  results?: Array<{ id?: string }>;
  status?: number;
  message?: string;
  error?: string;
};

async function parseJsonOrText(text: string): Promise<unknown> {
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function sanitizeDigits(value: string): string {
  return value.replace(/\D+/g, "");
}

async function fetchPaymentMethodId(params: {
  publicKey: string;
  baseUrl: string;
  cardNumber: string;
  timeoutMs?: number;
}): Promise<string> {
  const bin = params.cardNumber.slice(0, 8);
  if (bin.length !== 8) {
    throw new AppError(400, "INVALID_CARD_BIN", "Invalid card bin");
  }

  const baseUrl = params.baseUrl.replace(/\/$/, "");
  const url = `${baseUrl}/v1/payment_methods/search?public_key=${encodeURIComponent(
    params.publicKey,
  )}&marketplace=NONE&bins=${encodeURIComponent(bin)}`;
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    params.timeoutMs ?? DEFAULT_TIMEOUT_MS,
  );

  try {
    const response = await fetch(url, { signal: controller.signal });
    const text = await response.text();
    const payload = await parseJsonOrText(text);
    const body = (payload ?? {}) as PaymentMethodSearchResponse | string;

    if (response.status !== 200) {
      const message =
        typeof body === "string"
          ? body
          : (body.message ?? body.error ?? "Failed to fetch payment method");

      throw new AppError(
        502,
        "PAYMENT_METHOD_LOOKUP_FAILED",
        "Failed to fetch payment method",
        {
          status: response.status,
          message,
        },
      );
    }

    const paymentMethodId =
      typeof body === "string" ? null : (body.results?.[0]?.id ?? null);

    if (!paymentMethodId) {
      throw new AppError(
        502,
        "PAYMENT_METHOD_INVALID",
        "Missing payment method id",
      );
    }

    return paymentMethodId;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    if (error instanceof DOMException && error.name === "AbortError") {
      throw new AppError(
        502,
        "PAYMENT_METHOD_TIMEOUT",
        "Payment method request timed out",
      );
    }

    throw new AppError(
      502,
      "PAYMENT_METHOD_LOOKUP_FAILED",
      "Failed to fetch payment method",
    );
  } finally {
    clearTimeout(timeout);
  }
}

export async function createCardToken(params: {
  card: CardInput;
  publicKey: string;
  baseUrl: string;
  timeoutMs?: number;
}): Promise<{ card_token_id: string; payment_method_id: string }> {
  const sanitizedDocument = sanitizeDigits(params.card.cpfOrCnpj);
  const sanitizedCardNumber = sanitizeDigits(params.card.cardNumber);

  const documentType = getDocumentType(sanitizedDocument);
  if (!documentType) {
    throw new AppError(400, "INVALID_DOCUMENT", "Invalid card document");
  }

  const baseUrl = params.baseUrl.replace(/\/$/, "");
  const url = `${baseUrl}/v1/card_tokens?public_key=${encodeURIComponent(params.publicKey)}`;
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    params.timeoutMs ?? DEFAULT_TIMEOUT_MS,
  );

  // Nunca registrar os dados do cartão em log (número, CVV, documento).

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        cardholder: {
          identification: {
            type: documentType,
            number: sanitizedDocument,
          },
          name: params.card.name,
        },
        card_number: sanitizedCardNumber,
        expiration_month: params.card.expirationMonth,
        expiration_year: params.card.expirationYear,
        security_code: params.card.securityCode,
      }),
      signal: controller.signal,
    });

    const text = await response.text();
    const payload = await parseJsonOrText(text);
    const body = (payload ?? {}) as CardTokenResponse | string;

    if (response.status !== 201) {
      const message =
        typeof body === "string"
          ? body
          : (body.message ?? body.error ?? "Failed to create card token");

      throw new AppError(
        400,
        "CARD_TOKEN_FAILED",
        "Failed to create card token",
        {
          status: response.status,
          message,
        },
      );
    }

    const tokenId = typeof body === "string" ? null : (body.id ?? null);
    if (!tokenId) {
      throw new AppError(502, "CARD_TOKEN_INVALID", "Missing card token id");
    }

    const paymentMethodId = await fetchPaymentMethodId({
      publicKey: params.publicKey,
      baseUrl,
      cardNumber: sanitizedCardNumber,
      timeoutMs: params.timeoutMs,
    });

    return { card_token_id: tokenId, payment_method_id: paymentMethodId };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }

    if (error instanceof DOMException && error.name === "AbortError") {
      throw new AppError(
        502,
        "CARD_TOKEN_TIMEOUT",
        "Card token request timed out",
      );
    }

    throw new AppError(502, "CARD_TOKEN_FAILED", "Failed to create card token");
  } finally {
    clearTimeout(timeout);
  }
}
