DROP POLICY IF EXISTS "View patient records" ON public.tb_patient_records;
CREATE POLICY "View patient records"
ON public.tb_patient_records
FOR SELECT
USING (
  public.is_admin()
  OR (
    public.tb_patient_records.deleted_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.tb_patients AS pt
      LEFT JOIN public.tb_professionals AS p
        ON p.id = pt.professional_id
      WHERE
        pt.id = public.tb_patient_records.patient_id
        AND pt.deleted_at IS NULL
        AND (
          pt.user_id = public.get_my_uid()
          OR (
            p.deleted_at IS NULL
            AND p.user_id = public.get_my_uid()
          )
        )
    )
  )
);

DROP POLICY IF EXISTS "Create patient records" ON public.tb_patient_records;
CREATE POLICY "Create patient records"
ON public.tb_patient_records
FOR INSERT
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tb_patients AS pt
    JOIN public.tb_professionals AS p
      ON p.id = pt.professional_id
    WHERE
      pt.id = public.tb_patient_records.patient_id
      AND pt.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Update patient records" ON public.tb_patient_records;
CREATE POLICY "Update patient records"
ON public.tb_patient_records
FOR UPDATE
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tb_patients AS pt
    JOIN public.tb_professionals AS p
      ON p.id = pt.professional_id
    WHERE
      pt.id = public.tb_patient_records.patient_id
      AND pt.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tb_patients AS pt
    JOIN public.tb_professionals AS p
      ON p.id = pt.professional_id
    WHERE
      pt.id = public.tb_patient_records.patient_id
      AND pt.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Delete patient records" ON public.tb_patient_records;
CREATE POLICY "Delete patient records"
ON public.tb_patient_records
FOR DELETE
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tb_patients AS pt
    JOIN public.tb_professionals AS p
      ON p.id = pt.professional_id
    WHERE
      pt.id = public.tb_patient_records.patient_id
      AND pt.deleted_at IS NULL
      AND p.deleted_at IS NULL
      AND p.user_id = public.get_my_uid()
  )
);
