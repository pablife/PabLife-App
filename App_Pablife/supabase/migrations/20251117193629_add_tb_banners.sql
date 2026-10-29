CREATE TABLE IF NOT EXISTS public.tb_banners (
  id UUID NOT NULL PRIMARY KEY DEFAULT public.uuidv7(),
  title VARCHAR(100) NOT NULL CHECK (CHAR_LENGTH(title) <= 100),
  image_url TEXT NOT NULL,
  redirect_url TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  expiration_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_banners ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_banners TO authenticated;
REVOKE ALL ON public.tb_banners FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_banners
BEFORE UPDATE ON public.tb_banners
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
