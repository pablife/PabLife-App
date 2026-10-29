CREATE TABLE IF NOT EXISTS public.tb_mentoring_modules (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  mentoring_id UUID REFERENCES public.tb_mentorships (
    id
  ) ON DELETE CASCADE NOT NULL,
  name VARCHAR(200) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_mentoring_modules ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_mentoring_modules TO authenticated;
REVOKE ALL ON public.tb_mentoring_modules FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_mentoring_modules
BEFORE UPDATE ON public.tb_mentoring_modules
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
