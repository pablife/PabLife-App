import { defaultHeaders } from "./defaultHeaders.ts";
import { getDocumentType } from "./GetDocumentType.ts";
import { log } from "./Log.ts";
import { CardTokenDataType } from "./PaymentType.ts";

export async function getCardToken(card: CardTokenDataType): Promise<string | null> {
  try {
    const publicKey = Deno.env.get("MERCADOPAGO_PUBLIC_KEY");
    const response = await fetch(
      `https://api.mercadopago.com/v1/card_tokens?public_key=${publicKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cardholder: {
            identification: {
              type: getDocumentType(String(card.cpfOrCnpj)),
              number: card.cpfOrCnpj,
            },
            name: card.name,
          },
          card_number: card.cardNumber,
          expiration_month: card.expirationMonth,
          expiration_year: card.expirationYear,
          security_code: card.securityCode,
        }),
      },
    );

    const body = await response.json();

    if (response.status != 201) {
      throw {
        statusCode: response.status,
        success: false,
        message: body.message,
      };
    }

    log("CARD TOKEN: ", body);

    return body.id;
  } catch (error) {
    log("Ocorreu um erro ao tentar gerar token do cartão: ", error);
    throw error;
  }
}
