DROP POLICY IF EXISTS "View mentorships data" ON public.tb_mentorships;
CREATE POLICY "View mentorships data"
ON public.tb_mentorships FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_mentorships.deleted_at IS NULL
    AND public.get_my_uid() IS NOT NULL
  )
);

DROP POLICY IF EXISTS "Create mentorships data" ON public.tb_mentorships;
CREATE POLICY "Create mentorships data"
ON public.tb_mentorships FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update mentorships data" ON public.tb_mentorships;
CREATE POLICY "Update mentorships data"
ON public.tb_mentorships FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete mentorships data" ON public.tb_mentorships;
CREATE POLICY "Delete mentorships data"
ON public.tb_mentorships FOR DELETE
USING (
  public.is_admin()
);
