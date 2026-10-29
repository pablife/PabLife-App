DROP POLICY IF EXISTS "View notifications data" ON public.tb_notifications;
CREATE POLICY "View notifications data"
ON public.tb_notifications FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_notifications.deleted_at IS NULL
    AND public.get_my_uid() IS NOT NULL
    AND (
      public.tb_notifications.user_id = public.get_my_uid()
      OR public.tb_notifications.user_id IS NULL
    )
  )
);

DROP POLICY IF EXISTS "Create notifications data" ON public.tb_notifications;
CREATE POLICY "Create notifications data"
ON public.tb_notifications FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update notifications data" ON public.tb_notifications;
CREATE POLICY "Update notifications data"
ON public.tb_notifications FOR UPDATE
USING (
  public.is_admin()
  OR (
    public.tb_notifications.deleted_at IS NULL
    AND public.tb_notifications.user_id = public.get_my_uid()
  )
)
WITH CHECK (
  public.is_admin()
  OR (
    public.tb_notifications.deleted_at IS NULL
    AND public.tb_notifications.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Delete notifications data" ON public.tb_notifications;
CREATE POLICY "Delete notifications data"
ON public.tb_notifications FOR DELETE
USING (
  public.is_admin()
);
