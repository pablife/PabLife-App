import type { MercadoPagoService } from "./mercadopago_client.ts";

export type Topic =
  | "payment"
  | "merchant_order"
  | "order"
  | "subscription_preapproval";

const TOPIC_ALIASES: Record<string, Topic> = {
  payment: "payment",
  payments: "payment",
  merchant_order: "merchant_order",
  merchant_orders: "merchant_order",
  merchantorder: "merchant_order",
  order: "order",
  orders: "order",
  subscription_preapproval: "subscription_preapproval",
  preapproval: "subscription_preapproval",
  subscription: "subscription_preapproval",
};

export function routeTopic(topicOrType: string | null): Topic | null {
  if (!topicOrType) return null;
  const normalized = topicOrType.trim().toLowerCase();
  if (!normalized) return null;

  const direct = TOPIC_ALIASES[normalized];
  if (direct) return direct;

  if (
    normalized.includes("merchant_order") ||
    normalized.includes("merchantorder")
  ) {
    return "merchant_order";
  }
  if (
    normalized.includes("subscription_preapproval") ||
    normalized.includes("preapproval")
  ) {
    return "subscription_preapproval";
  }
  if (normalized.includes("payment")) return "payment";
  if (normalized.includes("order")) return "order";

  return null;
}

export async function getResourceSnapshot(
  topic: Topic,
  id: string,
  mpService: MercadoPagoService,
): Promise<{ snapshotType: Topic; snapshot: unknown }> {
  switch (topic) {
    case "payment":
      return {
        snapshotType: "payment",
        snapshot: await mpService.getPayment(id),
      };
    case "merchant_order":
      return {
        snapshotType: "merchant_order",
        snapshot: await mpService.getMerchantOrder(id),
      };
    case "order":
      return { snapshotType: "order", snapshot: await mpService.getOrder(id) };
    case "subscription_preapproval":
      return {
        snapshotType: "subscription_preapproval",
        snapshot: await mpService.getPreapproval(id),
      };
    default:
      return { snapshotType: topic, snapshot: null };
  }
}
