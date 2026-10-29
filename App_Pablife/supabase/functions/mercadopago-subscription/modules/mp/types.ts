export type MpPreapprovalResponse = {
  id?: string;
  status?: string;
  payer_email?: string;
  payer_id?: string;
  payer?: {
    id?: string;
    email?: string;
  };
  external_reference?: string;
  reason?: string;
  date_created?: string;
  last_modified?: string;
  date_last_updated?: string;
  next_payment_date?: string;
  renewed_at?: string;
  auto_recurring?: {
    frequency?: number;
    frequency_type?: "months" | "days";
    transaction_amount?: number;
    currency_id?: string;
    start_date?: string;
    end_date?: string | null;
  };
};

export type MpPaymentResponse = {
  id?: number | string;
  status?: string;
  status_detail?: string;
  external_reference?: string;
  transaction_amount?: number;
  currency_id?: string;
  installments?: number;
  payment_method_id?: string;
  payment_type_id?: string;
  issuer_id?: string;
  date_created?: string;
  date_approved?: string;
  date_last_updated?: string;
  payer?: {
    id?: string;
    email?: string;
  };
  transaction_details?: {
    net_received_amount?: number;
    total_paid_amount?: number;
  };
  transaction_amount_refunded?: number;
};

export type MpErrorPayload = {
  message?: string;
  error?: string;
  status?: number;
  cause?: unknown;
};
