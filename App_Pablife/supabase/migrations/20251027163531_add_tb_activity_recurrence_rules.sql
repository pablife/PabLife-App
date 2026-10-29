CREATE TABLE IF NOT EXISTS public.tb_activity_recurrence_rules (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  user_id UUID NOT NULL DEFAULT public.get_my_uid() REFERENCES public.tb_users (
    id
  ) ON DELETE CASCADE,
  start_at TIMESTAMP WITH TIME ZONE NOT NULL,
  -- Array of integers representing days of the week (0=Sunday, 6=Saturday)
  by_week_day SMALLINT [] NOT NULL,
  -- Day the week starts on (0=Sunday, 6=Saturday)
  week_start SMALLINT CHECK (week_start BETWEEN 0 AND 6) NOT NULL,
  timezone VARCHAR(100) NOT NULL, -- Timezone for the recurrence rule
  -- Raw representation of the recurrence rule (e.g., in RRULE format).
  -- In pattern format as defined by RFC 5545
  rrule_raw TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_activity_recurrence_rules
ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_activity_recurrence_rules TO authenticated;
REVOKE ALL ON public.tb_activity_recurrence_rules FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_activity_recurrence_rules
BEFORE UPDATE ON public.tb_activity_recurrence_rules
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_tb_activity_recurrence_rules_user_id
ON public.tb_activity_recurrence_rules (user_id);
