CREATE TABLE IF NOT EXISTS public.tb_patient_records (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  patient_id UUID REFERENCES public.tb_patients (
    id
  ) ON DELETE CASCADE NOT NULL,
  type VARCHAR(50) NOT NULL CHECK (
    type IN (
      'prescription',
      'meal_plan',
      'observation',
      'reflection',
      'practice',
      'note'
    )
  ),
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_patient_records ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_patient_records TO authenticated;
REVOKE ALL ON public.tb_patient_records FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_patient_records
BEFORE UPDATE ON public.tb_patient_records
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
