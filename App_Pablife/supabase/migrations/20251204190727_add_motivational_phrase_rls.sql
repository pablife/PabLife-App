DROP POLICY IF EXISTS "View motivacional phrases data"
ON public.tb_motivational_phrases;
CREATE POLICY "View motivacional phrases data"
ON public.tb_motivational_phrases FOR SELECT
USING (
  public.tb_motivational_phrases.deleted_at IS NULL
);

DROP POLICY IF EXISTS "Update motivacional phrases data"
ON public.tb_motivational_phrases;
CREATE POLICY "Update motivacional phrases data"
ON public.tb_motivational_phrases FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Create motivacional phrases data"
ON public.tb_motivational_phrases;
CREATE POLICY "Create motivacional phrases data"
ON public.tb_motivational_phrases FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete motivacional phrases data"
ON public.tb_motivational_phrases;
CREATE POLICY "Delete motivacional phrases data"
ON public.tb_motivational_phrases FOR DELETE
USING (
  public.is_admin()
);
