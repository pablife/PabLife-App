CREATE TABLE IF NOT EXISTS public.tb_appointment_times (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  professional_id UUID NOT NULL REFERENCES public.tb_professionals (id)
  ON DELETE CASCADE,
  appointment_recurrence_rule_id UUID
  REFERENCES public.tb_appointment_recurrence_rules (id)
  ON DELETE SET NULL,
  start_time_at TIME NOT NULL,
  finish_time_at TIME NOT NULL,
  due_at DATE,
  timezone VARCHAR(100) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_appointment_times ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_appointment_times TO authenticated;
REVOKE ALL ON public.tb_appointment_times FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_appointment_times
BEFORE UPDATE ON public.tb_appointment_times
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
