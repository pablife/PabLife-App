CREATE UNIQUE INDEX IF NOT EXISTS idx_tb_patients_appointment_id_unique
  ON public.tb_patients (appointment_id)
  WHERE deleted_at IS NULL;

DROP POLICY IF EXISTS "View patient data" ON public.tb_patients;
CREATE POLICY "View patient data"
ON public.tb_patients
FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_patients.deleted_at IS NULL
    AND (
      public.tb_patients.user_id = public.get_my_uid()
      OR EXISTS (
        SELECT 1
        FROM public.tb_professionals AS p
        WHERE
          p.id = public.tb_patients.professional_id
          AND p.deleted_at IS NULL
          AND p.user_id = public.get_my_uid()
      )
    )
  )
);

DROP POLICY IF EXISTS "Create patient data" ON public.tb_patients;
CREATE POLICY "Create patient data"
ON public.tb_patients
FOR INSERT
WITH CHECK (
  public.is_admin()
  OR (
    public.tb_patients.user_id = public.get_my_uid()
    AND public.tb_patients.deleted_at IS NULL
  )
);

DROP POLICY IF EXISTS "Update patient data" ON public.tb_patients;
CREATE POLICY "Update patient data"
ON public.tb_patients
FOR UPDATE
USING (
  public.is_admin()
  OR (
    public.tb_patients.deleted_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = public.tb_patients.professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
)
WITH CHECK (
  public.is_admin()
  OR (
    public.tb_patients.deleted_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = public.tb_patients.professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Delete patient data" ON public.tb_patients;
CREATE POLICY "Delete patient data"
ON public.tb_patients
FOR DELETE
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tb_professionals AS p
    WHERE
      p.id = public.tb_patients.professional_id
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);
