import { defaultHeaders } from "./defaultHeaders.ts";
import { CardType } from "./GetCardBrand.ts";
import { log } from "./Log.ts";

export type SaveCardData = {
  customerId: string;
  cardToken: string;
  cardHolderName: string;
  cardNumber: string;
  expirationMonth: number;
  expirationYear: number;
  cardType: CardType;
};

export type MercadoPagoCard = {
  id: string;
  customer_id: string;
  expiration_month: number;
  expiration_year: number;
  first_six_digits: string;
  last_four_digits: string;
  payment_method: {
    id: string;
    name: string;
    payment_type_id: string;
    thumbnail: string;
    secure_thumbnail: string;
  };
  security_code: {
    length: number;
    card_location: string;
  };
  issuer: {
    id: string;
    name: string;
  };
  cardholder: {
    name: string;
    identification: {
      number: string;
      type: string;
    };
  };
  date_created: string;
  date_last_updated: string;
  user_id: string;
  live_mode: boolean;
  require_esc: boolean;
  over_due_amount: number;
  external_reference: string;
};

/**
 * Salva um cartão para um customer no Mercado Pago
 * @param cardData Dados do cartão
 * @returns Dados do cartão salvo ou null em caso de erro
 */
export async function saveCard(cardData: SaveCardData): Promise<MercadoPagoCard | null> {
  try {
    log("Salvando cartão no Mercado Pago:", cardData);

    // A API do Mercado Pago aceita apenas o token para salvar o cartão.
    // issuer_id é opcional e, quando incorreto, pode causar erro 400.
    const requestBody = {
      token: cardData.cardToken,
      customer_id: cardData.customerId,
    } as const;

    const response = await fetch(
      `https://api.mercadopago.com/v1/customers/${cardData.customerId}/cards`,
      {
        method: "POST",
        headers: {
          ...defaultHeaders,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody),
      }
    );

    if (!response.ok) {
      let errorData: unknown = null;
      try { errorData = await response.json(); } catch { /* ignore */ }
      log("Erro ao salvar cartão:", { status: response.status, error: errorData });
      return null;
    }

    const card: MercadoPagoCard = await response.json();
    log("Cartão salvo com sucesso:", card);

    return card;
  } catch (error) {
    log("Erro ao salvar cartão:", error);
    return null;
  }
}

/**
 * Busca todos os cartões de um customer no Mercado Pago
 * @param customerId ID do customer
 * @returns Lista de cartões ou null em caso de erro
 */
export async function getCustomerCards(customerId: string): Promise<MercadoPagoCard[] | null> {
  try {
    log("Buscando cartões do customer:", customerId);

    const response = await fetch(
      `https://api.mercadopago.com/v1/customers/${customerId}/cards`,
      {
        method: "GET",
        headers: defaultHeaders,
      }
    );

    if (!response.ok) {
      log("Erro ao buscar cartões do customer");
      return null;
    }

    const cards: MercadoPagoCard[] = await response.json();
    log("Cartões encontrados:", cards);

    return cards;
  } catch (error) {
    log("Erro ao buscar cartões do customer:", error);
    return null;
  }
}

/**
 * Remove um cartão de um customer no Mercado Pago
 * @param customerId ID do customer
 * @param cardId ID do cartão
 * @returns true se removido com sucesso, false caso contrário
 */
export async function removeCustomerCard(customerId: string, cardId: string): Promise<boolean> {
  try {
    log("Removendo cartão do customer:", { customerId, cardId });

    const response = await fetch(
      `https://api.mercadopago.com/v1/customers/${customerId}/cards/${cardId}`,
      {
        method: "DELETE",
        headers: defaultHeaders,
      }
    );

    if (!response.ok) {
      log("Erro ao remover cartão do customer");
      return false;
    }

    log("Cartão removido com sucesso");
    return true;
  } catch (error) {
    log("Erro ao remover cartão do customer:", error);
    return false;
  }
}

/**
 * Busca um cartão salvo de um customer no Mercado Pago
 * @param customerId ID do customer
 * @param cardId ID do cartão
 * @returns Dados do cartão salvo ou null em caso de erro
 */
export async function getSavedCard(customerId: string, cardId: string): Promise<MercadoPagoCard | null> {
  try {
    log("Buscando cartão salvo do customer:", { customerId, cardId });

    const response = await fetch(
      `https://api.mercadopago.com/v1/customers/${customerId}/cards/${cardId}`,
      {
        method: "GET",
        headers: defaultHeaders,
      }
    );

    if (!response.ok) {
      log("Erro ao buscar cartão salvo do customer");
      return null;
    }

    const card: MercadoPagoCard = await response.json();
    log("Cartão salvo encontrado:", card);
    return card;
  } catch (error) {
    log("Erro ao buscar cartão salvo do customer:", error);
    return null;
  }
}