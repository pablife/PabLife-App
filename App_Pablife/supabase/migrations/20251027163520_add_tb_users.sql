CREATE TABLE IF NOT EXISTS public.tb_users (
  id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name VARCHAR(100) NOT NULL,
  email EXTENSIONS.CITEXT NOT NULL,
  phone VARCHAR(15) NOT NULL,
  cpf_document VARCHAR(11) NOT NULL CHECK (
    CHAR_LENGTH(cpf_document) = 11 AND cpf_document ~ '^[0-9]+$'
  ),
  image_url VARCHAR(255),
  terms_accepted BOOLEAN DEFAULT FALSE NOT NULL,
  role VARCHAR DEFAULT 'user' NOT NULL CHECK (
    role IN ('user', 'admin', 'professional')
  ),
  status VARCHAR(20) DEFAULT 'active' NOT NULL CHECK (
    status IN ('active', 'deactivated', 'deleted')
  ),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE,
  one_signal_user_id TEXT DEFAULT NULL,
  CONSTRAINT chk_active_user CHECK (
    (
      status IN ('active', 'deactivated')
      AND terms_accepted IS TRUE
      AND deleted_at IS NULL
    ) OR (
      status = 'deleted'
      AND deleted_at IS NOT NULL
    )
  )
);

ALTER TABLE IF EXISTS public.tb_users ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_users TO authenticated;
REVOKE ALL ON public.tb_users FROM anon;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_users_email ON public.tb_users (email)
WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_users_cpf_document ON public.tb_users (
  cpf_document
)
WHERE deleted_at IS NULL;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_users
BEFORE UPDATE ON public.tb_users
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
