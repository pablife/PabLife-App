CREATE TABLE IF NOT EXISTS public.tb_mentoring_categories (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  name VARCHAR(200) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_mentoring_categories ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_mentoring_categories TO authenticated;
REVOKE ALL ON public.tb_mentoring_categories FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_mentoring_categories
BEFORE UPDATE ON public.tb_mentoring_categories
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
