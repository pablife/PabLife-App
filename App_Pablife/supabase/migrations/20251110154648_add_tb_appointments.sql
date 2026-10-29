CREATE TABLE IF NOT EXISTS public.tb_appointments (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  scheduled_by UUID NOT NULL REFERENCES public.tb_users (
    id
  ) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES public.tb_professionals (
    id
  ) ON DELETE CASCADE,
  appointment_time_id UUID NOT NULL REFERENCES public.tb_appointment_times (
    id
  ) ON DELETE CASCADE,
  start_of_scheduled_window TIMESTAMP WITH TIME ZONE NOT NULL,
  end_of_scheduled_window TIMESTAMP WITH TIME ZONE NOT NULL,
  timeslot TSTZRANGE GENERATED ALWAYS AS (
    TSTZRANGE(start_of_scheduled_window, end_of_scheduled_window, '[)')
  ) STORED,
  started_at TIMESTAMP WITH TIME ZONE,
  finished_at TIMESTAMP WITH TIME ZONE,
  status VARCHAR NOT NULL DEFAULT 'scheduled' CHECK (
    status IN ('scheduled', 'completed', 'cancelled', 'no_show')
  ),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE public.tb_appointments
ADD CONSTRAINT tb_appointments_no_overlap_per_staff
EXCLUDE USING gist (
  appointment_time_id WITH =,
  professional_id WITH =,
  timeslot WITH &&
)
WHERE (status IN ('scheduled'));

ALTER TABLE IF EXISTS public.tb_patients
ADD COLUMN IF NOT EXISTS appointment_id UUID REFERENCES public.tb_appointments (
  id
) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.tb_appointments ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_appointments TO authenticated;
REVOKE ALL ON public.tb_appointments FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_appointments
BEFORE UPDATE ON public.tb_appointments
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
