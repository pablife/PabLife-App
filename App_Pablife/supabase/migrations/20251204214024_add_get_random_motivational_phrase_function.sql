-- Returns a random non-deleted motivational phrase
CREATE OR REPLACE FUNCTION public.get_random_motivational_phrase()
RETURNS TABLE (
  id UUID,
  content TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
)
LANGUAGE sql
AS $$
    SELECT id,
           content,
           created_at,
           updated_at,
           deleted_at
    FROM public.tb_motivational_phrases
    WHERE deleted_at IS NULL
    ORDER BY random()
    LIMIT 1;
$$;

COMMENT ON FUNCTION public.get_random_motivational_phrase
IS 'Returns a random motivational phrase that has not been soft-deleted.';
