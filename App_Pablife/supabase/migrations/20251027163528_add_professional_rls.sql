DROP POLICY IF EXISTS "View professional data" ON public.tb_professionals;
CREATE POLICY "View professional data"
ON public.tb_professionals FOR SELECT
USING (
  public.tb_professionals.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_user() OR public.is_professional())
      AND public.tb_professionals.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Update professional data" ON public.tb_professionals;
CREATE POLICY "Update professional data"
ON public.tb_professionals FOR UPDATE
USING (
  public.tb_professionals.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_professional())
      AND public.tb_professionals.user_id = public.get_my_uid()
    )
  )
)
WITH CHECK (
  public.tb_professionals.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      (public.is_professional())
      AND public.tb_professionals.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Create professional data" ON public.tb_professionals;
CREATE POLICY "Create professional data"
ON public.tb_professionals FOR INSERT
WITH CHECK (
  public.tb_professionals.deleted_at IS NULL
  AND (public.is_admin())
);

DROP POLICY IF EXISTS "Delete professional data" ON public.tb_professionals;
CREATE POLICY "Delete professional data"
ON public.tb_professionals FOR DELETE
USING (
  public.tb_professionals.deleted_at IS NULL
  AND (public.is_admin())
);
