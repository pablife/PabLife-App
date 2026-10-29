CREATE TABLE IF NOT EXISTS public.tb_rules_professional_transfers (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  price_per_consultation DECIMAL(10, 2) NOT NULL,
  transfer_rate DECIMAL(3, 2) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  become_effective_at TIMESTAMP WITH TIME ZONE NOT NULL,
  ceases_to_be_in_force_at TIMESTAMP WITH TIME ZONE,
  timeslot TSTZRANGE GENERATED ALWAYS AS (
    TSTZRANGE(become_effective_at, ceases_to_be_in_force_at, '[)')
  ) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE public.tb_rules_professional_transfers
ADD CONSTRAINT tb_rules_professional_transfers_no_overlap
EXCLUDE USING gist (
  timeslot WITH &&
);

INSERT INTO public.tb_rules_professional_transfers (
  price_per_consultation,
  transfer_rate,
  is_active,
  become_effective_at,
  ceases_to_be_in_force_at,
  created_at,
  updated_at
) VALUES (
  70.00,
  0.90,
  TRUE,
  NOW() - INTERVAL '1 year',
  NULL,
  NOW(),
  NOW()
);

ALTER TABLE IF EXISTS public.tb_rules_professional_transfers
ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_rules_professional_transfers TO authenticated;
REVOKE ALL ON public.tb_rules_professional_transfers FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_rules_professional_transfers
BEFORE UPDATE ON public.tb_rules_professional_transfers
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
