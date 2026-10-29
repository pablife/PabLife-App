-- pending = Assinatura aguardando pagamento.
-- active = Assinatura ativa do usuário.
-- cancelled = Assinatura encerrada por falta de pagamento.

CREATE TABLE IF NOT EXISTS public.tb_user_subscriptions (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  user_id UUID NOT NULL REFERENCES public.tb_users (id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES public.tb_subscription_plans (
    id
  ) ON DELETE RESTRICT,
  mp_preapproval_id TEXT NOT NULL UNIQUE,
  mp_payer_id TEXT NULL,
  mp_payer_email TEXT NULL,
  external_reference TEXT NOT NULL,
  status TEXT NOT NULL CHECK (
    status IN ('pending', 'active', 'cancelled')
  ),
  reason TEXT NULL,
  frequency INT NULL,
  frequency_type TEXT NULL,              -- ex.: "months"
  transaction_amount NUMERIC(12, 2) NULL,
  currency_id TEXT NULL,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  mp_date_created TIMESTAMPTZ NULL,
  mp_last_modified TIMESTAMPTZ NULL,
  has_first_payment BOOLEAN NOT NULL DEFAULT FALSE,
  has_preapproval BOOLEAN NOT NULL DEFAULT FALSE,
  next_payment_date TIMESTAMPTZ NULL,
  started_at TIMESTAMP WITH TIME ZONE,
  renewed_at TIMESTAMP WITH TIME ZONE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE IF EXISTS public.tb_user_subscriptions ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_user_subscriptions TO authenticated;
REVOKE ALL ON public.tb_user_subscriptions FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_user_subscriptions
BEFORE UPDATE ON public.tb_user_subscriptions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_next_payment_date
ON public.tb_user_subscriptions (
  next_payment_date
);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id
ON public.tb_user_subscriptions (
  plan_id
);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id
ON public.tb_user_subscriptions (
  user_id
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_uq_user_one_active_subscription
ON public.tb_user_subscriptions (user_id)
WHERE status = 'active';

CREATE UNIQUE INDEX IF NOT EXISTS idx_uq_user_one_pending_subscription
ON public.tb_user_subscriptions (user_id)
WHERE status = 'pending';

CREATE UNIQUE INDEX IF NOT EXISTS idx_uq_user_one_open_per_plan
ON public.tb_user_subscriptions (user_id, plan_id)
WHERE status IN ('active', 'pending');
