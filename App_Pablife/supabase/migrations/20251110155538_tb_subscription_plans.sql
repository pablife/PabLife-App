CREATE TABLE IF NOT EXISTS public.tb_subscription_plans (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  preapproval_plan_id VARCHAR(255) NOT NULL,
  reason VARCHAR(100) NOT NULL,
  features TEXT [] NULL,
  transaction_amount DECIMAL(10, 2) NOT NULL,
  currency_id VARCHAR(3) DEFAULT 'BRL' NOT NULL,
  duration_months INTEGER NOT NULL,
  consultations INTEGER NOT NULL,
  image_path TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE,
  CONSTRAINT chk_preapproval_plan_id CHECK (
    CHAR_LENGTH(preapproval_plan_id) > 0
    AND CHAR_LENGTH(preapproval_plan_id) <= 255
  ),
  CONSTRAINT chk_reason CHECK (
    CHAR_LENGTH(reason) > 0 AND CHAR_LENGTH(reason) <= 100
  ),
  CONSTRAINT chk_duration_months CHECK (duration_months > 0),
  CONSTRAINT chk_consultations CHECK (consultations >= 0)
);

ALTER TABLE IF EXISTS public.tb_subscription_plans ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_subscription_plans TO authenticated;
REVOKE ALL ON public.tb_subscription_plans FROM anon;
GRANT SELECT ON public.tb_subscription_plans TO anon;

-- Trigger to update the updated_at timestamp on record modification
CREATE OR REPLACE TRIGGER set_updated_at_trigger_subscription_plans
BEFORE UPDATE ON public.tb_subscription_plans
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Index for faster lookups by preapproval_plan_id
CREATE INDEX idx_subscription_plans_preapproval_plan_id
ON public.tb_subscription_plans (
  preapproval_plan_id
);

-- Comments on columns
COMMENT ON COLUMN public.tb_subscription_plans.reason
IS 'Nome/Descrição do plano (ex: Plano Lite, Plano Plus, Plano Premium)';
COMMENT ON COLUMN public.tb_subscription_plans.features
IS 'Lista de benefícios/features do plano';
COMMENT ON COLUMN public.tb_subscription_plans.consultations
IS 'Número de consultas incluídas no plano';
COMMENT ON COLUMN public.tb_subscription_plans.image_path
IS 'Caminho do asset da imagem do plano (ex: assets/pages/premium/lite.png)';
