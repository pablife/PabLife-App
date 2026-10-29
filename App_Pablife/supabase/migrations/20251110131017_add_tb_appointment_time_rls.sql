DROP POLICY IF EXISTS "View appointment time data"
ON public.tb_appointment_times;
CREATE POLICY "View appointment time data"
ON public.tb_appointment_times FOR SELECT
USING (
  public.tb_appointment_times.deleted_at IS NULL
  AND (public.is_user() OR public.is_professional() OR public.is_admin())
);

DROP POLICY IF EXISTS "Update appointment time data"
ON public.tb_appointment_times;
CREATE POLICY "Update appointment time data"
ON public.tb_appointment_times FOR UPDATE
USING (
  public.tb_appointment_times.deleted_at IS NULL
  AND public.is_professional()
  AND EXISTS (
    SELECT 1
    FROM public.tb_professionals p
    WHERE
      p.id = public.tb_appointment_times.professional_id
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
)
WITH CHECK (
  public.is_professional()
  AND EXISTS (
    SELECT 1
    FROM public.tb_professionals p
    WHERE
      p.id = public.tb_appointment_times.professional_id
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Create appointment time data"
ON public.tb_appointment_times;
CREATE POLICY "Create appointment time data"
ON public.tb_appointment_times FOR INSERT
WITH CHECK (
  public.tb_appointment_times.deleted_at IS NULL
  AND public.is_professional()
  AND EXISTS (
    SELECT 1
    FROM public.tb_professionals p
    WHERE
      p.id = public.tb_appointment_times.professional_id
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Delete appointment time data"
ON public.tb_appointment_times;
CREATE POLICY "Delete appointment time data"
ON public.tb_appointment_times FOR DELETE
USING (
  public.tb_appointment_times.deleted_at IS NULL
  AND public.is_professional()
  AND EXISTS (
    SELECT 1
    FROM public.tb_professionals p
    WHERE
      p.id = public.tb_appointment_times.professional_id
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);
