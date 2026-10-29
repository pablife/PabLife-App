CREATE TABLE IF NOT EXISTS public.tb_motivational_phrases (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_motivational_phrases ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_motivational_phrases TO authenticated;
REVOKE ALL ON public.tb_motivational_phrases FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_motivational_phrases
BEFORE UPDATE ON public.tb_motivational_phrases
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
