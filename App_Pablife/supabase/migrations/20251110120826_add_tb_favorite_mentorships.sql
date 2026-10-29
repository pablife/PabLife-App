CREATE TABLE IF NOT EXISTS public.tb_favorite_mentorships (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  user_id UUID REFERENCES public.tb_users (id) ON DELETE CASCADE NOT NULL,
  mentorship_id UUID REFERENCES public.tb_mentorships (
    id
  ) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE IF EXISTS public.tb_favorite_mentorships ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_favorite_mentorships TO authenticated;
REVOKE ALL ON public.tb_favorite_mentorships FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_favorite_mentorships
BEFORE UPDATE ON public.tb_favorite_mentorships
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
