ALTER TABLE IF EXISTS public.tb_activity_registers
ADD COLUMN IF NOT EXISTS activity_date DATE;

UPDATE public.tb_activity_registers ar
SET
  activity_date = COALESCE(
    (a.due_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::DATE,
    (ar.registered_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::DATE
  )
FROM public.tb_activities a
WHERE
  ar.activity_id = a.id
  AND ar.activity_date IS NULL;

ALTER TABLE IF EXISTS public.tb_activity_registers
ALTER COLUMN activity_date SET NOT NULL;
