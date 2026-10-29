DROP POLICY IF EXISTS "View module lessons data" ON public.tb_module_lessons;
CREATE POLICY "View module lessons data"
ON public.tb_module_lessons FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_module_lessons.deleted_at IS NULL
    AND public.get_my_uid() IS NOT NULL
  )
);

DROP POLICY IF EXISTS "Create module lessons data" ON public.tb_module_lessons;
CREATE POLICY "Create module lessons data"
ON public.tb_module_lessons FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update module lessons data" ON public.tb_module_lessons;
CREATE POLICY "Update module lessons data"
ON public.tb_module_lessons FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete module lessons data" ON public.tb_module_lessons;
CREATE POLICY "Delete module lessons data"
ON public.tb_module_lessons FOR DELETE
USING (
  public.is_admin()
);
