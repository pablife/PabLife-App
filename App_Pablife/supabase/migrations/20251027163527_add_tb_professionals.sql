CREATE TABLE IF NOT EXISTS public.tb_professionals (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  user_id UUID NOT NULL REFERENCES public.tb_users (id) ON DELETE CASCADE,
  type VARCHAR(100) NOT NULL CHECK (type IN ('nutritionist', 'psychologist')),
  description TEXT DEFAULT NULL,
  validation_document_url VARCHAR(255) NOT NULL,
  validation_status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (
    validation_status IN ('pending', 'approved', 'rejected')
  ),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_professionals ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_professionals TO authenticated;
REVOKE ALL ON public.tb_professionals FROM anon;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_professionals_user_id
ON public.tb_professionals (
  user_id
)
WHERE deleted_at IS NULL;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_professionals
BEFORE UPDATE ON public.tb_professionals
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
