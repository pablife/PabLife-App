import { safeLog } from "./safeLog.ts";

export type Logger = (event: string, meta?: Record<string, unknown>) => void;

export function createLogger(
  functionName: string,
  requestId?: string | null,
): { requestId: string; log: Logger } {
  const id = requestId && requestId.trim().length > 0
    ? requestId
    : crypto.randomUUID();
  const prefix = `[${functionName}]`;

  const log: Logger = (event, meta = {}) => {
    safeLog(`${prefix} ${event}`, {
      request_id: id,
      ...meta,
    });
  };

  return { requestId: id, log };
}
