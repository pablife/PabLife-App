DROP POLICY IF EXISTS "View activity recurrence rules"
ON public.tb_activity_recurrence_rules;
CREATE POLICY "View activity recurrence rules"
ON public.tb_activity_recurrence_rules FOR SELECT
USING (
  public.tb_activity_recurrence_rules.deleted_at IS NULL
  AND (public.is_user() OR public.is_professional() OR public.is_admin())
);

DROP POLICY IF EXISTS "Create activity recurrence rules"
ON public.tb_activity_recurrence_rules;
CREATE POLICY "Create activity recurrence rules"
ON public.tb_activity_recurrence_rules FOR INSERT
WITH CHECK (
  public.tb_activity_recurrence_rules.deleted_at IS NULL
  AND public.tb_activity_recurrence_rules.user_id = public.get_my_uid()
);

DROP POLICY IF EXISTS "Update activity recurrence rules"
ON public.tb_activity_recurrence_rules;
CREATE POLICY "Update activity recurrence rules"
ON public.tb_activity_recurrence_rules FOR UPDATE
USING (
  public.tb_activity_recurrence_rules.deleted_at IS NULL
  AND public.tb_activity_recurrence_rules.user_id = public.get_my_uid()
)
WITH CHECK (
  public.tb_activity_recurrence_rules.deleted_at IS NULL
  AND public.tb_activity_recurrence_rules.user_id = public.get_my_uid()
);

DROP POLICY IF EXISTS "Delete activity recurrence rules"
ON public.tb_activity_recurrence_rules;
CREATE POLICY "Delete activity recurrence rules"
ON public.tb_activity_recurrence_rules FOR DELETE
USING (
  public.tb_activity_recurrence_rules.deleted_at IS NULL
  AND public.tb_activity_recurrence_rules.user_id = public.get_my_uid()
);
