DROP POLICY IF EXISTS "View rules professional transfer data"
ON public.tb_rules_professional_transfers;
CREATE POLICY "View rules professional transfer data"
ON public.tb_rules_professional_transfers FOR SELECT
USING (
  public.is_admin()
);

DROP POLICY IF EXISTS "Update rules professional transfer data"
ON public.tb_rules_professional_transfers;
CREATE POLICY "Update rules professional transfer data"
ON public.tb_rules_professional_transfers FOR UPDATE
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Create rules professional transfer data"
ON public.tb_rules_professional_transfers;
CREATE POLICY "Create rules professional transfer data"
ON public.tb_rules_professional_transfers FOR INSERT
WITH CHECK (
  public.is_admin()
);

DROP POLICY IF EXISTS "Delete rules professional transfer data"
ON public.tb_rules_professional_transfers;
CREATE POLICY "Delete rules professional transfer data"
ON public.tb_rules_professional_transfers FOR DELETE
USING (
  public.is_admin()
);
