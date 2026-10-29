// Centralized logger for delete-account edge function.
export function log(message: string, data?: unknown) {
  if (data === undefined) {
    console.log(`[delete-account] ${message}`);
    return;
  }

  console.log(`[delete-account] ${message}`, data);
}
