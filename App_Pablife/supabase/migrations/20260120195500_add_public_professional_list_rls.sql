DROP POLICY IF EXISTS "View approved professionals" ON public.tb_professionals;
CREATE POLICY "View approved professionals"
ON public.tb_professionals FOR SELECT
USING (
  public.tb_professionals.deleted_at IS NULL
  AND public.tb_professionals.validation_status = 'approved'
  AND public.get_my_uid() IS NOT NULL
);

DROP POLICY IF EXISTS "View approved professional users" ON public.tb_users;
CREATE POLICY "View approved professional users"
ON public.tb_users FOR SELECT
USING (
  public.tb_users.deleted_at IS NULL
  AND public.tb_users.status = 'active'
  AND public.get_my_uid() IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM public.tb_professionals p
    WHERE
      p.user_id = public.tb_users.id
      AND p.deleted_at IS NULL
      AND p.validation_status = 'approved'
  )
);
