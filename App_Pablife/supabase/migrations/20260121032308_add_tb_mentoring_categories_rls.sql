DROP POLICY IF EXISTS "View mentoring categories data"
ON public.tb_mentoring_categories;
CREATE POLICY "View mentoring categories data"
ON public.tb_mentoring_categories FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_mentoring_categories.deleted_at IS NULL
    AND public.get_my_uid() IS NOT NULL
  )
);

DROP POLICY IF EXISTS "Create mentoring categories data"
ON public.tb_mentoring_categories;
CREATE POLICY "Create mentoring categories data"
ON public.tb_mentoring_categories FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update mentoring categories data"
ON public.tb_mentoring_categories;
CREATE POLICY "Update mentoring categories data"
ON public.tb_mentoring_categories FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete mentoring categories data"
ON public.tb_mentoring_categories;
CREATE POLICY "Delete mentoring categories data"
ON public.tb_mentoring_categories FOR DELETE
USING (
  public.is_admin()
);
