ALTER TABLE IF EXISTS public.tb_appointment_times
ADD COLUMN IF NOT EXISTS appointment_recurrence_rule_id UUID
REFERENCES public.tb_appointment_recurrence_rules (
  id
) ON DELETE SET NULL;
