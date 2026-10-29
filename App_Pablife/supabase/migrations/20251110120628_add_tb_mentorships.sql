CREATE TABLE IF NOT EXISTS public.tb_mentorships (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  category_id UUID REFERENCES public.tb_mentoring_categories (
    id
  ) ON DELETE CASCADE NOT NULL,
  title VARCHAR(200) NOT NULL,
  author VARCHAR(100) NOT NULL,
  duration INT NOT NULL CHECK (duration >= 0) DEFAULT 0,
  image_url TEXT,
  description TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_mentorships ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_mentorships TO authenticated;
REVOKE ALL ON public.tb_mentorships FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_mentorships
BEFORE UPDATE ON public.tb_mentorships
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
