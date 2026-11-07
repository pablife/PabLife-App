-- Anotações de sessão: compartilhadas (o paciente vê) ou privadas (só o
-- profissional que escreveu vê; nem o painel administrativo). Dado sensível.
--
-- Plano alimentar, prescrição e prática ficam compartilhados, como hoje. As
-- demais (observação, reflexão, anotação) passam a ser privadas. Nada é
-- apagado: só deixa de aparecer para o paciente.

ALTER TABLE public.tb_patient_records
  ADD COLUMN IF NOT EXISTS visibility text;

UPDATE public.tb_patient_records
   SET visibility = CASE
     WHEN type IN ('meal_plan', 'prescription', 'practice') THEN 'shared'
     ELSE 'private'
   END
 WHERE visibility IS NULL;

ALTER TABLE public.tb_patient_records
  ALTER COLUMN visibility SET NOT NULL,
  ADD CONSTRAINT tb_patient_records_visibility_check
  CHECK (visibility IN ('shared', 'private'));

-- Versões do app que ainda não escolhem a visibilidade seguem a regra do tipo.
CREATE OR REPLACE FUNCTION public.set_patient_record_visibility()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF NEW.visibility IS NULL THEN
    NEW.visibility := CASE
      WHEN NEW.type IN ('meal_plan', 'prescription', 'practice') THEN 'shared'
      ELSE 'private'
    END;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_patient_record_visibility ON public.tb_patient_records;
CREATE TRIGGER set_patient_record_visibility
  BEFORE INSERT ON public.tb_patient_records
  FOR EACH ROW EXECUTE FUNCTION public.set_patient_record_visibility();

-- O profissional dono do registro: o mesmo de tb_patients, que liga paciente
-- e profissional.
CREATE OR REPLACE FUNCTION public.is_my_patient_record(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tb_patients pt
    JOIN public.tb_professionals p ON p.id = pt.professional_id
    WHERE pt.id = p_patient_id
      AND pt.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_my_own_record(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tb_patients pt
    WHERE pt.id = p_patient_id
      AND pt.deleted_at IS NULL
      AND pt.user_id = public.get_my_uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_my_patient_record(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_my_own_record(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_my_patient_record(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_my_own_record(uuid) TO authenticated;

DROP POLICY IF EXISTS "View patient records" ON public.tb_patient_records;
DROP POLICY IF EXISTS "Create patient records" ON public.tb_patient_records;
DROP POLICY IF EXISTS "Update patient records" ON public.tb_patient_records;
DROP POLICY IF EXISTS "Delete patient records" ON public.tb_patient_records;

CREATE POLICY "View patient records"
  ON public.tb_patient_records
  FOR SELECT
  USING (
    (deleted_at IS NULL AND public.is_my_patient_record(patient_id))
    OR (
      visibility = 'shared'
      AND (
        public.is_admin()
        OR (deleted_at IS NULL AND public.is_my_own_record(patient_id))
      )
    )
  );

CREATE POLICY "Create patient records"
  ON public.tb_patient_records
  FOR INSERT
  WITH CHECK (
    public.is_my_patient_record(patient_id)
    OR (public.is_admin() AND visibility = 'shared')
  );

CREATE POLICY "Update patient records"
  ON public.tb_patient_records
  FOR UPDATE
  USING (
    public.is_my_patient_record(patient_id)
    OR (public.is_admin() AND visibility = 'shared')
  )
  WITH CHECK (
    public.is_my_patient_record(patient_id)
    OR (public.is_admin() AND visibility = 'shared')
  );

CREATE POLICY "Delete patient records"
  ON public.tb_patient_records
  FOR DELETE
  USING (
    public.is_my_patient_record(patient_id)
    OR (public.is_admin() AND visibility = 'shared')
  );
