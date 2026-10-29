export type DeleteAccountResponse = {
  success: boolean;
  code: string;
  message: string;
  data?: Record<string, unknown>;
};

export function jsonResponse(
  body: DeleteAccountResponse,
  status = 200,
  headers: Record<string, string> = {}
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
  });
}
