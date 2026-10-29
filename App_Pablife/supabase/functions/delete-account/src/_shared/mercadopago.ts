import { log } from "./logger.ts";

export type MercadoPagoConfig = {
  accessToken: string;
  apiBase: string;
};

export type PreapprovalSearchResult = {
  results: Array<{
    id?: string;
    status?: string;
  }>;
};

export async function searchPreapprovals(params: {
  config: MercadoPagoConfig;
  payerEmail: string;
  preapprovalPlanId: string;
}): Promise<PreapprovalSearchResult> {
  const query = new URLSearchParams({
    payer_email: params.payerEmail,
    preapproval_plan_id: params.preapprovalPlanId,
  }).toString();

  const url = `${params.config.apiBase}/preapproval/search?${query}`;
  const response = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${params.config.accessToken}`,
      Accept: "application/json",
    },
  });

  const payloadText = await response.text();
  if (!response.ok) {
    log("Mercado Pago search preapprovals failed", {
      status: response.status,
      body: payloadText,
    });
    throw new Error("MP_PREAPPROVAL_SEARCH_FAILED");
  }

  try {
    return JSON.parse(payloadText) as PreapprovalSearchResult;
  } catch {
    log("Mercado Pago search preapprovals invalid JSON", { body: payloadText });
    throw new Error("MP_PREAPPROVAL_SEARCH_FAILED");
  }
}

export async function cancelPreapproval(params: {
  config: MercadoPagoConfig;
  preapprovalId: string;
}): Promise<void> {
  const url = `${params.config.apiBase}/preapproval/${params.preapprovalId}`;
  const response = await fetch(url, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${params.config.accessToken}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ status: "cancelled" }),
  });

  const payloadText = await response.text();
  if (!response.ok) {
    log("Mercado Pago cancel preapproval failed", {
      status: response.status,
      body: payloadText,
      preapprovalId: params.preapprovalId,
    });
    throw new Error("MP_PREAPPROVAL_CANCEL_FAILED");
  }
}

export function isTempPreapprovalId(value: string | null): boolean {
  return typeof value === "string" && value.startsWith("TEMP-");
}
