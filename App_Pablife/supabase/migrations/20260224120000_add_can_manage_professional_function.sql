CREATE OR REPLACE FUNCTION public.can_manage_professional(
  professional_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  current_uid UUID := public.get_my_uid();
BEGIN
  IF current_uid IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.tb_professionals p
    WHERE p.id = professional_id
      AND p.deleted_at IS NULL
      AND (
        p.user_id = current_uid
        OR public.is_admin()
      )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.can_manage_professional(UUID) FROM public;
GRANT EXECUTE ON FUNCTION public.can_manage_professional(UUID) TO authenticated;
