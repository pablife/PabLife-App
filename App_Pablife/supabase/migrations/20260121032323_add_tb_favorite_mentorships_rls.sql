DROP POLICY IF EXISTS "View favorite mentorships data"
ON public.tb_favorite_mentorships;
CREATE POLICY "View favorite mentorships data"
ON public.tb_favorite_mentorships FOR SELECT
USING (
  public.is_admin()
  OR public.tb_favorite_mentorships.user_id = public.get_my_uid()
);

DROP POLICY IF EXISTS "Create favorite mentorships data"
ON public.tb_favorite_mentorships;
CREATE POLICY "Create favorite mentorships data"
ON public.tb_favorite_mentorships FOR INSERT
WITH CHECK (
  public.is_admin()
  OR public.tb_favorite_mentorships.user_id = public.get_my_uid()
);

DROP POLICY IF EXISTS "Update favorite mentorships data"
ON public.tb_favorite_mentorships;
CREATE POLICY "Update favorite mentorships data"
ON public.tb_favorite_mentorships FOR UPDATE
USING (
  public.is_admin()
  OR public.tb_favorite_mentorships.user_id = public.get_my_uid()
)
WITH CHECK (
  public.is_admin()
  OR public.tb_favorite_mentorships.user_id = public.get_my_uid()
);

DROP POLICY IF EXISTS "Delete favorite mentorships data"
ON public.tb_favorite_mentorships;
CREATE POLICY "Delete favorite mentorships data"
ON public.tb_favorite_mentorships FOR DELETE
USING (
  public.is_admin()
  OR public.tb_favorite_mentorships.user_id = public.get_my_uid()
);
