CREATE TABLE IF NOT EXISTS public.tb_mercadopago_webhook_events (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  provider TEXT NOT NULL DEFAULT 'mercadopago',
  request_id TEXT NOT NULL UNIQUE,
  signature_valid BOOLEAN NOT NULL,
  event_label TEXT,
  resource_kind TEXT,
  resource_action TEXT,
  resource_id TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  raw_headers JSONB NOT NULL DEFAULT '{}'::JSONB,
  raw_query JSONB NOT NULL DEFAULT '{}'::JSONB,
  raw_body JSONB NOT NULL DEFAULT '{}'::JSONB,
  sdk_snapshot_type TEXT,
  sdk_snapshot JSONB,
  processing_notes TEXT,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE IF EXISTS public.tb_mercadopago_webhook_events
ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_mercadopago_webhook_events TO authenticated;
REVOKE ALL ON public.tb_mercadopago_webhook_events FROM anon;

CREATE INDEX IF NOT EXISTS idx_tb_mercadopago_webhook_events_received_at
ON public.tb_mercadopago_webhook_events (received_at);

CREATE INDEX IF NOT EXISTS idx_tb_mercadopago_webhook_events_resource_id
ON public.tb_mercadopago_webhook_events (resource_id);

CREATE INDEX IF NOT EXISTS idx_tb_mercadopago_webhook_events_event_label
ON public.tb_mercadopago_webhook_events (event_label);

CREATE INDEX IF NOT EXISTS idx_tb_mercadopago_webhook_events_signature_valid
ON public.tb_mercadopago_webhook_events (signature_valid);

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_mercadopago_webhook_events
BEFORE UPDATE ON public.tb_mercadopago_webhook_events
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
