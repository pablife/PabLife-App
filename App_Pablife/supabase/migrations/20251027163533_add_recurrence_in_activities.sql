ALTER TABLE IF EXISTS public.tb_activities
ADD COLUMN IF NOT EXISTS activity_recurrence_rule_id UUID
REFERENCES public.tb_activity_recurrence_rules (
  id
);
