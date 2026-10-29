CREATE TABLE IF NOT EXISTS public.tb_activity_registers (
  id UUID PRIMARY KEY DEFAULT public.uuidv7() NOT NULL,
  activity_id UUID REFERENCES public.tb_activities (
    id
  ) ON DELETE CASCADE NOT NULL,
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE IF EXISTS public.tb_activity_registers ENABLE ROW LEVEL SECURITY;
GRANT SELECT,
INSERT,
UPDATE,
DELETE ON public.tb_activity_registers TO authenticated;
REVOKE ALL ON public.tb_activity_registers FROM anon;

CREATE OR REPLACE TRIGGER set_updated_at_trigger_tb_activity_registers
BEFORE UPDATE ON public.tb_activity_registers
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP POLICY IF EXISTS "View activity register data"
ON public.tb_activity_registers;
CREATE POLICY "View activity register data"
ON public.tb_activity_registers FOR SELECT
USING (
  public.tb_activity_registers.deleted_at IS NULL
  AND public.is_user()
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities a
    WHERE
      a.id = public.tb_activity_registers.activity_id
      AND a.deleted_at IS NULL
      AND a.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Update activity register data"
ON public.tb_activity_registers;
CREATE POLICY "Update activity register data"
ON public.tb_activity_registers FOR UPDATE
USING (
  public.tb_activity_registers.deleted_at IS NULL
  AND public.is_user()
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities a
    WHERE
      a.id = public.tb_activity_registers.activity_id
      AND a.deleted_at IS NULL
      AND a.user_id = public.get_my_uid()
  )
)
WITH CHECK (
  public.tb_activity_registers.deleted_at IS NULL
  AND public.is_user()
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities a
    WHERE
      a.id = public.tb_activity_registers.activity_id
      AND a.deleted_at IS NULL
      AND a.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Create activity register data"
ON public.tb_activity_registers;
CREATE POLICY "Create activity register data"
ON public.tb_activity_registers FOR INSERT
WITH CHECK (
  public.tb_activity_registers.deleted_at IS NULL
  AND public.is_user()
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities a
    WHERE
      a.id = public.tb_activity_registers.activity_id
      AND a.deleted_at IS NULL
      AND a.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Delete activity register data"
ON public.tb_activity_registers;
CREATE POLICY "Delete activity register data"
ON public.tb_activity_registers FOR DELETE
USING (
  public.tb_activity_registers.deleted_at IS NULL
  AND public.is_user()
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities a
    WHERE
      a.id = public.tb_activity_registers.activity_id
      AND a.deleted_at IS NULL
      AND a.user_id = public.get_my_uid()
  )
);
