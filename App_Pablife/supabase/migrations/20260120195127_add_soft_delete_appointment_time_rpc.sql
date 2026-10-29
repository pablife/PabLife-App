CREATE OR REPLACE FUNCTION public.soft_delete_appointment_time(
  appointment_time_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  appointment_professional_id UUID;
BEGIN
  IF NOT public.is_professional() THEN
    RAISE EXCEPTION 'not_professional';
  END IF;

  SELECT professional_id
    INTO appointment_professional_id
  FROM public.tb_appointment_times
  WHERE id = appointment_time_id;

  IF appointment_professional_id IS NULL THEN
    RAISE EXCEPTION 'appointment_time_not_found';
  END IF;

  IF NOT public.can_manage_professional(appointment_professional_id) THEN
    RAISE EXCEPTION 'not_owner';
  END IF;

  UPDATE public.tb_appointment_times
  SET deleted_at = now()
  WHERE id = appointment_time_id
    AND deleted_at IS NULL;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.soft_delete_appointment_time(UUID) FROM public;
GRANT EXECUTE ON FUNCTION public.soft_delete_appointment_time(
  UUID
) TO authenticated;
