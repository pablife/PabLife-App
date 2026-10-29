DROP POLICY IF EXISTS "View appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions;
CREATE POLICY "View appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions FOR SELECT
USING (
  public.tb_appointment_recurrence_exceptions.deleted_at IS NULL
  AND (public.is_user() OR public.is_professional() OR public.is_admin())
);

DROP POLICY IF EXISTS "Create appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions;
CREATE POLICY "Create appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions FOR INSERT
WITH CHECK (
  public.is_admin()
  OR (
    public.is_professional()
    AND EXISTS (
      SELECT 1
      FROM public.tb_appointment_times AS t
      INNER JOIN public.tb_professionals AS p ON p.id = t.professional_id
      WHERE
        t.id = public.tb_appointment_recurrence_exceptions.appointment_time_id
        AND t.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Update appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions;
CREATE POLICY "Update appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions FOR UPDATE
USING (
  public.is_admin()
  OR (
    public.is_professional()
    AND EXISTS (
      SELECT 1
      FROM public.tb_appointment_times AS t
      INNER JOIN public.tb_professionals AS p ON p.id = t.professional_id
      WHERE
        t.id = public.tb_appointment_recurrence_exceptions.appointment_time_id
        AND t.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
)
WITH CHECK (
  public.is_admin()
  OR (
    public.is_professional()
    AND EXISTS (
      SELECT 1
      FROM public.tb_appointment_times AS t
      INNER JOIN public.tb_professionals AS p ON p.id = t.professional_id
      WHERE
        t.id = public.tb_appointment_recurrence_exceptions.appointment_time_id
        AND t.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Delete appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions;
CREATE POLICY "Delete appointment recurrence exceptions"
ON public.tb_appointment_recurrence_exceptions FOR DELETE
USING (
  public.is_admin()
  OR (
    public.is_professional()
    AND EXISTS (
      SELECT 1
      FROM public.tb_appointment_times AS t
      INNER JOIN public.tb_professionals AS p ON p.id = t.professional_id
      WHERE
        t.id = public.tb_appointment_recurrence_exceptions.appointment_time_id
        AND t.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);
