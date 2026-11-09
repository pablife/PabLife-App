export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info, x-idempotency-key",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function handleOptions(): Response {
  return new Response(null, { headers: { ...corsHeaders } });
}
