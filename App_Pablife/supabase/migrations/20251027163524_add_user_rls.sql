DROP POLICY IF EXISTS "View account data" ON public.tb_users;
CREATE POLICY "View account data"
ON public.tb_users FOR SELECT
USING (
  public.tb_users.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_user() OR public.is_professional())
      AND public.tb_users.id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Update account data" ON public.tb_users;
CREATE POLICY "Update account data"
ON public.tb_users FOR UPDATE
USING (
  public.tb_users.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_user() OR public.is_professional())
      AND public.tb_users.id = public.get_my_uid()
    )
  )
)
WITH CHECK (
  public.tb_users.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_user() OR public.is_professional())
      AND public.tb_users.id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Create account data" ON public.tb_users;
CREATE POLICY "Create account data"
ON public.tb_users FOR INSERT
WITH CHECK (
  public.tb_users.deleted_at IS NULL
  AND (public.is_admin())
);

DROP POLICY IF EXISTS "Delete account data" ON public.tb_users;
CREATE POLICY "Delete account data"
ON public.tb_users FOR DELETE
USING (
  public.tb_users.deleted_at IS NULL
  AND (public.is_admin())
);
