DROP POLICY IF EXISTS "View activity data" ON public.tb_activities;
CREATE POLICY "View activity data"
ON public.tb_activities FOR SELECT
USING (
  public.tb_activities.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_user() OR public.is_professional())
      AND public.tb_activities.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Update activity data" ON public.tb_activities;
CREATE POLICY "Update activity data"
ON public.tb_activities FOR UPDATE
USING (
  public.tb_activities.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
    )
  )
)
WITH CHECK (
  public.tb_activities.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Create activity data" ON public.tb_activities;
CREATE POLICY "Create activity data"
ON public.tb_activities FOR INSERT
WITH CHECK (
  public.tb_activities.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Delete activity data" ON public.tb_activities;
CREATE POLICY "Delete activity data"
ON public.tb_activities FOR DELETE
USING (
  public.tb_activities.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
    )
  )
);
