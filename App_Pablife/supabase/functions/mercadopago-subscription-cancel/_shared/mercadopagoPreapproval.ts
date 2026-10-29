import type { EdgeLogger } from "./edgeLogger.ts";

export type MercadoPagoConfig = {
  accessToken: string;
  apiBase: string;
};

export async function cancelPreapproval(params: {
  config: MercadoPagoConfig;
  preapprovalId: string;
  log?: EdgeLogger;
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
    params.log?.("Mercado Pago cancel preapproval failed", {
      status: response.status,
      body: payloadText,
      preapprovalId: params.preapprovalId,
    });
    throw new Error("MP_PREAPPROVAL_CANCEL_FAILED");
  }
}
