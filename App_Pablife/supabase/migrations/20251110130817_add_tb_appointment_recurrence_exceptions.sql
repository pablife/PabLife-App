CREATE TABLE IF NOT EXISTS public.tb_appointment_recurrence_exceptions (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  appointment_time_id UUID NOT NULL REFERENCES public.tb_appointment_times (id)
  ON DELETE CASCADE,
  slot_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMPTZ
);

ALTER TABLE IF EXISTS public.tb_appointment_recurrence_exceptions
ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_appointment_recurrence_exceptions
TO authenticated;
REVOKE ALL ON public.tb_appointment_recurrence_exceptions FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_appointment_recurrence_exceptions
BEFORE UPDATE ON public.tb_appointment_recurrence_exceptions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_appointment_recurrence_exceptions_time_date_unique
ON public.tb_appointment_recurrence_exceptions (appointment_time_id, slot_date)
WHERE deleted_at IS NULL;
