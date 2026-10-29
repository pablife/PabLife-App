CREATE TABLE IF NOT EXISTS public.tb_module_lessons (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  mentoring_module_id UUID NOT NULL REFERENCES public.tb_mentoring_modules (
    id
  ) ON DELETE SET NULL,
  lesson_number INT NOT NULL CHECK (lesson_number >= 0),
  title VARCHAR(200) NOT NULL,
  video_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_module_lessons
ADD CONSTRAINT uq_module_lesson_number_per_module
UNIQUE (mentoring_module_id, lesson_number);

ALTER TABLE IF EXISTS public.tb_module_lessons ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_module_lessons TO authenticated;
REVOKE ALL ON public.tb_module_lessons FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_module_lessons
BEFORE UPDATE ON public.tb_module_lessons
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
