DROP POLICY IF EXISTS "View appointment recurrence rules"
ON public.tb_appointment_recurrence_rules;
CREATE POLICY "View appointment recurrence rules"
ON public.tb_appointment_recurrence_rules FOR SELECT
USING (
  public.tb_appointment_recurrence_rules.deleted_at IS NULL
  AND (public.is_user() OR public.is_professional() OR public.is_admin())
);

DROP POLICY IF EXISTS "Create appointment recurrence rules"
ON public.tb_appointment_recurrence_rules;
CREATE POLICY "Create appointment recurrence rules"
ON public.tb_appointment_recurrence_rules FOR INSERT
WITH CHECK (
  public.is_professional() OR public.is_admin()
);

DROP POLICY IF EXISTS "Update appointment recurrence rules"
ON public.tb_appointment_recurrence_rules;
CREATE POLICY "Update appointment recurrence rules"
ON public.tb_appointment_recurrence_rules FOR UPDATE
USING (
  public.is_admin()
  OR (
    public.is_professional()
    AND EXISTS (
      SELECT 1
      FROM public.tb_appointment_times AS t
      INNER JOIN public.tb_professionals AS p ON p.id = t.professional_id
      WHERE
        t.appointment_recurrence_rule_id
        = public.tb_appointment_recurrence_rules.id
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
        t.appointment_recurrence_rule_id
        = public.tb_appointment_recurrence_rules.id
        AND t.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Delete appointment recurrence rules"
ON public.tb_appointment_recurrence_rules;
CREATE POLICY "Delete appointment recurrence rules"
ON public.tb_appointment_recurrence_rules FOR DELETE
USING (
  public.is_admin()
  OR (
    public.is_professional()
    AND EXISTS (
      SELECT 1
      FROM public.tb_appointment_times AS t
      INNER JOIN public.tb_professionals AS p ON p.id = t.professional_id
      WHERE
        t.appointment_recurrence_rule_id
        = public.tb_appointment_recurrence_rules.id
        AND t.deleted_at IS NULL
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);
