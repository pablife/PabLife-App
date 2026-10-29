export const defaultHeaders = {
  "Content-Type": "application/json;charset=UTF-8",
  "Authorization": "Bearer " + Deno.env.get("MERCADOPAGO_TOKEN"),
};
