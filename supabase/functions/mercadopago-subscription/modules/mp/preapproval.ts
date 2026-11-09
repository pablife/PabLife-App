import { AppError, isAppError } from "../utils/errors.ts";
import { MpClient } from "./mpClient.ts";
import type { MpPreapprovalResponse } from "./types.ts";

function isNotFoundError(error: AppError): boolean {
  const details = error.details as Record<string, unknown> | null | undefined;
  const status = details?.status;
  if (typeof status === "number") return status === 404;
  if (typeof status === "string") return status === "404";
  return false;
}

export async function getPreapprovalById(
  client: MpClient,
  preapprovalId: string,
): Promise<MpPreapprovalResponse | null> {
  try {
    return await client.request<MpPreapprovalResponse>(
      `/preapproval/${preapprovalId}`,
      { method: "GET" },
    );
  } catch (error) {
    if (isAppError(error) && isNotFoundError(error)) {
      return null;
    }
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(
      502,
      "MP_REQUEST_FAILED",
      "Mercado Pago request failed",
    );
  }
}
