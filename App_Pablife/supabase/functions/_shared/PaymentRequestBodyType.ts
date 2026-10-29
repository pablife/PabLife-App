export type PaymentRequestBody = {
  transaction_amount: number;
  notification_url: string | undefined;
  description: string;
  payment_method_id: string;
  payer: {
    email: string;
    first_name: string;
    last_name: string;
    identification: {
      type: string | null;
      number: string;
    };
    id?: string; // Para cartões salvos
    type?: string; // Para cartões salvos
  };
  installments?: number;
  token?: string | null;
};
