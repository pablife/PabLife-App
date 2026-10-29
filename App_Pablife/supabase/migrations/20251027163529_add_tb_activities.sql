CREATE TABLE IF NOT EXISTS public.tb_activities (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  user_id UUID REFERENCES public.tb_users (id) ON DELETE CASCADE NOT NULL,
  type VARCHAR(10) NOT NULL CHECK (type IN ('goal', 'task', 'note')),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  priority VARCHAR(20) NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  due_at TIMESTAMP WITH TIME ZONE,
  all_day BOOLEAN DEFAULT FALSE NOT NULL,
  timezone VARCHAR(100) NOT NULL,
  steps VARCHAR [] NOT NULL DEFAULT ARRAY[]::VARCHAR [],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_activities ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_activities TO authenticated;
REVOKE ALL ON public.tb_activities FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_activities
BEFORE UPDATE ON public.tb_activities
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
