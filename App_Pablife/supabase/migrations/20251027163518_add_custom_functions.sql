CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW IS DISTINCT FROM OLD THEN
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.set_updated_at() FROM public;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_my_uid()
RETURNS UUID
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_uid() FROM public;
GRANT EXECUTE ON FUNCTION public.get_my_uid() TO authenticated;

CREATE OR REPLACE FUNCTION public.uuidv7()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
VOLATILE
PARALLEL SAFE
SET search_path = public, pg_temp
AS $$
  -- Replace the first 48 bits of a uuidv4 with the current
  -- number of milliseconds since 1970-01-01 UTC
  -- and set the "ver" field to 7 by setting additional bits
  SELECT encode(
    set_bit(
      set_bit(
        overlay(uuid_send(extensions.gen_random_uuid()) placing
          substring(int8send((extract(epoch FROM clock_timestamp())*1000)::bigint) FROM 3)
          FROM 1 FOR 6),
        52, 1),
      53, 1), 'hex')::uuid;
$$;

REVOKE ALL ON FUNCTION public.uuidv7() FROM public;
GRANT EXECUTE ON FUNCTION public.uuidv7() TO anon, authenticated;
