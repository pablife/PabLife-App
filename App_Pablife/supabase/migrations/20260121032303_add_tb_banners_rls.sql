DROP POLICY IF EXISTS "View banners data" ON public.tb_banners;
CREATE POLICY "View banners data"
ON public.tb_banners FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_banners.deleted_at IS NULL
    AND public.get_my_uid() IS NOT NULL
  )
);

DROP POLICY IF EXISTS "Create banners data" ON public.tb_banners;
CREATE POLICY "Create banners data"
ON public.tb_banners FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update banners data" ON public.tb_banners;
CREATE POLICY "Update banners data"
ON public.tb_banners FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete banners data" ON public.tb_banners;
CREATE POLICY "Delete banners data"
ON public.tb_banners FOR DELETE
USING (
  public.is_admin()
);
