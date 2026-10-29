-- approved = O pagamento foi aprovado e creditado.
-- authorized = O pagamento foi autorizado, mas ainda não foi capturado.
-- cancelled = O pagamento foi cancelado por uma das partes ou porque o prazo
-- para pagamento expirou.
-- charged_back = Foi realizado um chargeback no cartão de crédito do comprador.
-- in_mediation = Os usuários iniciaram uma disputa.
-- in_process = O pagamento está sendo analisado.
-- pending = O usuário ainda não concluiu o processo de pagamento.
-- refunded = O pagamento foi reembolsado ao usuário.
-- rejected = O pagamento foi recusado. O usuário pode tentar pagar novamente.

CREATE TABLE IF NOT EXISTS public.tb_subscription_transactions (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  user_subscription_id UUID NOT NULL REFERENCES public.tb_user_subscriptions (
    id
  ) ON DELETE CASCADE,
  mp_payment_id BIGINT NOT NULL UNIQUE,  -- payment.id costuma ser numérico
  external_reference TEXT NULL,
  status TEXT NOT NULL CHECK (
    status IN (
      'approved',
      'authorized',
      'cancelled',
      'charged_back',
      'in_mediation',
      'in_process',
      'pending',
      'refunded',
      'rejected'
    )
  ),
  status_detail TEXT NULL,
  transaction_amount NUMERIC(12, 2) NULL,
  currency_id TEXT NULL,
  installments INT NULL,
  payment_method_id TEXT NULL,
  payment_type_id TEXT NULL,
  attempt_no INT NOT NULL DEFAULT 1,
  is_retry BOOLEAN GENERATED ALWAYS AS (
    attempt_no > 1
  ) STORED,
  issuer_id TEXT NULL,
  mp_payer_id TEXT NULL,
  mp_payer_email TEXT NULL,
  mp_date_created TIMESTAMPTZ NULL,
  mp_date_approved TIMESTAMPTZ NULL,
  mp_date_last_updated TIMESTAMPTZ NULL,
  net_received_amount NUMERIC(12, 2) NULL,
  total_paid_amount NUMERIC(12, 2) NULL,
  refunded_amount NUMERIC(12, 2) NULL,
  mp_payment_snapshot JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE IF EXISTS public.tb_subscription_transactions
ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE ON public.tb_subscription_transactions TO authenticated;
REVOKE ALL ON public.tb_subscription_transactions FROM anon;

CREATE INDEX IF NOT EXISTS idx_subscription_transactions_user_subscription_id
ON public.tb_subscription_transactions (
  user_subscription_id
);
CREATE INDEX IF NOT EXISTS idx_subscription_transactions_status
ON public.tb_subscription_transactions (
  status
);
CREATE INDEX IF NOT EXISTS idx_subscription_transactions_mp_date_created
ON public.tb_subscription_transactions (
  mp_date_created
);
