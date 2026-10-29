CREATE OR REPLACE FUNCTION public.int2_array_unique(arr SMALLINT [])
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN arr IS NULL OR (
    SELECT COUNT(*) = COUNT(DISTINCT x)
    FROM unnest(arr) AS u(x)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.int2_array_unique(SMALLINT []) FROM public;
GRANT EXECUTE ON FUNCTION public.int2_array_unique(
  SMALLINT []
) TO authenticated;

CREATE OR REPLACE FUNCTION public.int2_array_all_between(
  arr SMALLINT [], min_v INT, max_v INT, allow_zero BOOLEAN DEFAULT TRUE
) RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN arr IS NULL OR NOT EXISTS (
    SELECT 1 FROM unnest(arr) AS u(x)
    WHERE x < min_v OR x > max_v OR (NOT allow_zero AND x = 0)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.int2_array_all_between(
  SMALLINT [], INT, INT, BOOLEAN
) FROM public;
GRANT EXECUTE ON FUNCTION public.int2_array_all_between(
  SMALLINT [], INT, INT, BOOLEAN
) TO authenticated;

CREATE OR REPLACE FUNCTION TZ_VALID(tz TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN tz IS NULL OR tz IN (SELECT name FROM pg_timezone_names);
END;
$$;

REVOKE ALL ON FUNCTION public.tz_valid(TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.tz_valid(TEXT) TO authenticated;
