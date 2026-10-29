DROP POLICY IF EXISTS "View mentoring modules data"
ON public.tb_mentoring_modules;
CREATE POLICY "View mentoring modules data"
ON public.tb_mentoring_modules FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_mentoring_modules.deleted_at IS NULL
    AND public.get_my_uid() IS NOT NULL
  )
);

DROP POLICY IF EXISTS "Create mentoring modules data"
ON public.tb_mentoring_modules;
CREATE POLICY "Create mentoring modules data"
ON public.tb_mentoring_modules FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update mentoring modules data"
ON public.tb_mentoring_modules;
CREATE POLICY "Update mentoring modules data"
ON public.tb_mentoring_modules FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete mentoring modules data"
ON public.tb_mentoring_modules;
CREATE POLICY "Delete mentoring modules data"
ON public.tb_mentoring_modules FOR DELETE
USING (
  public.is_admin()
);
