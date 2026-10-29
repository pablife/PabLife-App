DROP POLICY IF EXISTS "View related appointments" ON public.tb_appointments;
CREATE POLICY "View related appointments"
ON public.tb_appointments
FOR SELECT
USING (
  public.tb_appointments.deleted_at IS NULL
  AND (
    public.is_admin()
    OR public.tb_appointments.scheduled_by = public.get_my_uid()
    OR EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Create appointments" ON public.tb_appointments;
CREATE POLICY "Create appointments"
ON public.tb_appointments
FOR INSERT
WITH CHECK (
  public.is_admin()
  OR public.tb_appointments.scheduled_by = public.get_my_uid()
);

DROP POLICY IF EXISTS "Update appointments" ON public.tb_appointments;
CREATE POLICY "Update appointments"
ON public.tb_appointments
FOR UPDATE
USING (
  public.tb_appointments.deleted_at IS NULL
  AND (
    public.is_admin()
    OR public.tb_appointments.scheduled_by = public.get_my_uid()
    OR EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
)
WITH CHECK (
  public.tb_appointments.deleted_at IS NULL
  AND (
    public.is_admin()
    OR public.tb_appointments.scheduled_by = public.get_my_uid()
    OR EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Delete appointments" ON public.tb_appointments;
CREATE POLICY "Delete appointments"
ON public.tb_appointments
FOR DELETE
USING (public.is_admin());
