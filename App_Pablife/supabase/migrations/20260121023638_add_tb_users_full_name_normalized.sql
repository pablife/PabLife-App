CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.normalize_name(input_text TEXT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT extensions.unaccent(lower(trim($1)));
$$;

REVOKE ALL ON FUNCTION public.normalize_name(TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.normalize_name(TEXT) TO authenticated;

ALTER TABLE IF EXISTS public.tb_users
ADD COLUMN IF NOT EXISTS full_name_normalized TEXT
GENERATED ALWAYS AS (public.normalize_name(full_name)) STORED;

CREATE INDEX IF NOT EXISTS idx_tb_users_full_name_normalized
ON public.tb_users (full_name_normalized);
