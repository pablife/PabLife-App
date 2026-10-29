CREATE TABLE IF NOT EXISTS public.tb_notifications (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  user_id UUID REFERENCES public.tb_users (id) ON DELETE CASCADE,
  title VARCHAR(100) NOT NULL CHECK (CHAR_LENGTH(title) <= 100),
  message TEXT NOT NULL,
  metadata JSONB,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_notifications ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_notifications TO authenticated;
REVOKE ALL ON public.tb_notifications FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_notifications
BEFORE UPDATE ON public.tb_notifications
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
