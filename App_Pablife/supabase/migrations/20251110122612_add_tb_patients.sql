CREATE TABLE IF NOT EXISTS public.tb_patients (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  user_id UUID REFERENCES public.tb_users (id) ON DELETE CASCADE NOT NULL,
  professional_id UUID REFERENCES public.tb_professionals (
    id
  ) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_patients ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_patients TO authenticated;
REVOKE ALL ON public.tb_patients FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_patients
BEFORE UPDATE ON public.tb_patients
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
