import { corsHeaders } from "./cors.ts";

export async function parseJsonSafely(
  req: Request,
): Promise<{ data?: unknown; error?: string }> {
  const text = await req.text();
  if (!text || !text.trim()) {
    return { error: "Request body is required" };
  }

  try {
    return { data: JSON.parse(text) };
  } catch {
    return { error: "Invalid JSON body" };
  }
}

export function jsonOk(
  payload: unknown,
  status = 200,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
      ...headers,
    },
  });
}

export function jsonError(
  status: number,
  payload: unknown,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
      ...headers,
    },
  });
}
