import { CardType } from "./GetCardBrand.ts";

export type PaymentType = {
  method: string;
  userId: number;
  appointmentId?: number;
  description: string;
  payer: {
    email: string;
    firstName: string;
    lastName: string;
    cpfOrCnpj: string;
  };
  card?: CardDataType;
  savedCard?: {
    cardId: string;
    securityCode: string;
    installments: number;
  };
};

// Tipo base para dados do cartão necessários para gerar o token
export type CardTokenDataType = {
  name: string;
  cpfOrCnpj: string;
  cardNumber: string;
  expirationMonth: number;
  expirationYear: number;
  securityCode: string;
};

// Tipo completo com campos adicionais para pagamentos
export type CardDataType = CardTokenDataType & {
  installments: number;
  type: CardType | 'saved_card';
};
