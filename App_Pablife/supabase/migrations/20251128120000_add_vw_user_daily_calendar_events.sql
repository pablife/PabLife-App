-- Policies required so the view can respect RLS and still resolve dependencies
DROP POLICY IF EXISTS "View activity registers by owner"
ON public.tb_activity_registers;
CREATE POLICY "View activity registers by owner"
ON public.tb_activity_registers
FOR SELECT
USING (
  public.tb_activity_registers.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities AS a
    WHERE
      a.id = activity_id
      AND a.deleted_at IS NULL
      AND (
        public.is_admin() OR (
          (public.is_user() OR public.is_professional())
          AND a.user_id = public.get_my_uid()
        )
      )
  )
);

DROP POLICY IF EXISTS "View activity recurrence rules by owner"

ON public.tb_activity_recurrence_rules;
CREATE POLICY "View activity recurrence rules by owner"
ON public.tb_activity_recurrence_rules
FOR SELECT
USING (
  public.tb_activity_recurrence_rules.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.tb_activities AS a
    WHERE
      a.activity_recurrence_rule_id = id
      AND a.deleted_at IS NULL
      AND (
        public.is_admin() OR (
          (public.is_user() OR public.is_professional())
          AND a.user_id = public.get_my_uid()
        )
      )
  )
);

DROP POLICY IF EXISTS "View related appointments" ON public.tb_appointments;
CREATE POLICY "View related appointments"
ON public.tb_appointments
FOR SELECT
USING (
  public.tb_appointments.deleted_at IS NULL
  AND (
    public.is_admin()
    OR public.tb_appointments.scheduled_by = public.get_my_uid()
    OR EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "View related appointment times"
ON public.tb_appointment_times;
CREATE POLICY "View related appointment times"
ON public.tb_appointment_times
FOR SELECT
USING (
  public.tb_appointment_times.deleted_at IS NULL
  AND (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.tb_professionals AS p
      WHERE
        p.id = professional_id
        AND p.deleted_at IS NULL
        AND p.user_id = public.get_my_uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.tb_appointments AS ap
      WHERE
        ap.appointment_time_id = id
        AND ap.deleted_at IS NULL
        AND ap.scheduled_by = public.get_my_uid()
    )
  )
);

-- Ajustes em get_user_calendar_events: corrige horas de início/fim para tasks
-- (recorrentes e únicas),
-- notes e goals considerando timezone, e garante end_at em todos os eventos.

DROP VIEW IF EXISTS public.vw_user_daily_calendar_events;
DROP FUNCTION IF EXISTS public.get_user_calendar_events(DATE);

CREATE OR REPLACE FUNCTION public.get_user_calendar_events(
  target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  event_id UUID,
  event_type TEXT,
  type TEXT,
  title TEXT,
  description TEXT,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  all_day BOOLEAN,
  timezone VARCHAR,
  event_date DATE,
  is_completed BOOLEAN,
  appointment_id UUID,
  professional_id UUID,
  status TEXT
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
WITH ref_day AS (
  SELECT target_date AS day_ref
),
my_account AS (
  SELECT public.get_my_uid() AS user_id, public.is_admin() AS is_admin
),
activity_base AS (
  SELECT
    a.id,
    a.user_id,
    a.type,
    a.name,
    a.description,
    a.all_day,
    a.due_at,
    a.timezone,
    a.activity_recurrence_rule_id,
    a.created_at,
    rd.day_ref
  FROM ref_day rd
  CROSS JOIN my_account ma
  JOIN public.tb_activities a ON a.deleted_at IS NULL
    AND (ma.is_admin OR a.user_id = ma.user_id)
),
-- Goals: diários do created_at até due_at (inclusive), dia inteiro
goal_base AS (
  SELECT
    a.id AS activity_id,
    a.user_id,
    a.name,
    a.description,
    COALESCE(a.timezone, 'UTC') AS timezone,
    (a.created_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::date AS created_date,
    CASE WHEN a.due_at IS NOT NULL
         THEN (a.due_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::date
         ELSE NULL END AS due_date,
    rd.day_ref
  FROM ref_day rd
  CROSS JOIN my_account ma
  JOIN public.tb_activities a ON a.deleted_at IS NULL
    AND a.type = 'goal'
    AND (ma.is_admin OR a.user_id = ma.user_id)
),
goal_completion AS (
  SELECT
    gb.activity_id,
    MIN((ar.registered_at AT TIME ZONE gb.timezone)::date) AS conclusion_date
  FROM goal_base gb
  LEFT JOIN public.tb_activity_registers ar
    ON ar.activity_id = gb.activity_id
   AND ar.deleted_at IS NULL
  GROUP BY gb.activity_id
),
goal_occurrences AS (
  SELECT
    gb.activity_id,
    'goal'::text AS type,
    gb.name,
    gb.description,
    TRUE AS all_day,
    gb.timezone,
    -- início do dia na timezone da meta
    ((rd.day_ref::timestamp) AT TIME ZONE gb.timezone) AS start_at,
    -- fim do dia na timezone da meta
    (((rd.day_ref + 1)::timestamp - INTERVAL '1 millisecond') AT TIME ZONE gb.timezone) AS end_at,
    rd.day_ref AS event_date,
    gc.conclusion_date
  FROM goal_base gb
  JOIN ref_day rd ON TRUE
  LEFT JOIN goal_completion gc ON gc.activity_id = gb.activity_id
  WHERE (
    gb.due_date IS NOT NULL
      AND rd.day_ref BETWEEN gb.created_date AND gb.due_date
  ) OR (
    gb.due_date IS NULL
      AND rd.day_ref = gb.created_date
  )
),
-- Tasks únicas: due_at definido e sem regra de recorrência
single_tasks AS (
  SELECT
    ab.id AS activity_id,
    ab.type,
    ab.name,
    ab.description,
    FALSE AS all_day,
    COALESCE(ab.timezone, 'UTC') AS timezone,
    ab.due_at AS start_at,
    ab.due_at + INTERVAL '1 hour' AS end_at,
    (ab.due_at AT TIME ZONE COALESCE(ab.timezone, 'UTC'))::date AS event_date
  FROM activity_base ab
  WHERE ab.type = 'task'
    AND ab.activity_recurrence_rule_id IS NULL
    AND ab.due_at IS NOT NULL
    AND ab.day_ref = (ab.due_at AT TIME ZONE COALESCE(ab.timezone, 'UTC'))::date
),
-- Notes: data específica em due_at
note_occurrences AS (
  SELECT
    ab.id AS activity_id,
    ab.type,
    ab.name,
    ab.description,
    FALSE AS all_day,
    COALESCE(ab.timezone, 'UTC') AS timezone,
    ab.due_at AS start_at,
    ab.due_at + INTERVAL '1 hour' AS end_at,
    (ab.due_at AT TIME ZONE COALESCE(ab.timezone, 'UTC'))::date AS event_date
  FROM activity_base ab
  WHERE ab.type = 'note'
    AND ab.activity_recurrence_rule_id IS NULL
    AND ab.due_at IS NOT NULL
    AND ab.day_ref = (ab.due_at AT TIME ZONE COALESCE(ab.timezone, 'UTC'))::date
),
-- Tasks recorrentes: usar sempre a regra de recorrência
task_recurring_on_day AS (
  SELECT
    ab.id AS activity_id,
    ab.type,
    ab.name,
    ab.description,
    COALESCE(arr.timezone, ab.timezone, 'UTC') AS timezone,
    rd.day_ref,
    EXTRACT(DOW FROM rd.day_ref::date)::int AS dow_in_rule_tz,
    (arr.start_at AT TIME ZONE COALESCE(arr.timezone, ab.timezone, 'UTC'))::date AS rule_start_date,
    (arr.start_at AT TIME ZONE COALESCE(arr.timezone, ab.timezone, 'UTC'))::time AS rule_start_time,
    arr.by_week_day
  FROM ref_day rd
  CROSS JOIN my_account ma
  JOIN activity_base ab ON ab.activity_recurrence_rule_id IS NOT NULL
    AND ab.type = 'task'
    AND ab.due_at IS NULL
  JOIN public.tb_activity_recurrence_rules arr
    ON arr.id = ab.activity_recurrence_rule_id
   AND arr.deleted_at IS NULL
  WHERE rd.day_ref >= (arr.start_at AT TIME ZONE COALESCE(arr.timezone, ab.timezone, 'UTC'))::date
),
task_recurring_occurrences AS (
  SELECT
    tr.activity_id,
    tr.type,
    tr.name,
    tr.description,
    -- all_day é verdadeiro apenas se cobre todos os dias da semana
    (tr.by_week_day @> ARRAY[0,1,2,3,4,5,6]::smallint[]) AS all_day,
    tr.timezone,
    ((tr.day_ref::timestamp + tr.rule_start_time) AT TIME ZONE tr.timezone) AS start_at,
    ((tr.day_ref::timestamp + tr.rule_start_time) AT TIME ZONE tr.timezone) + INTERVAL '1 hour' AS end_at,
    tr.day_ref AS event_date
  FROM task_recurring_on_day tr
  WHERE tr.dow_in_rule_tz::smallint = ANY(tr.by_week_day)
),
activity_occurrences AS (
  SELECT * FROM single_tasks
  UNION ALL
  SELECT * FROM note_occurrences
  UNION ALL
  SELECT * FROM task_recurring_occurrences
),
activity_events AS (
  SELECT
    ao.activity_id AS event_id,
    'activity'::text AS event_type,
    ao.type,
    ao.name AS title,
    ao.description,
    ao.start_at,
    ao.end_at,
    ao.all_day,
    ao.timezone,
    ao.event_date,
    COALESCE(ar.is_completed, FALSE) AS is_completed,
    NULL::uuid AS appointment_id,
    NULL::uuid AS professional_id,
    CASE WHEN COALESCE(ar.is_completed, FALSE) THEN 'completed' ELSE 'pending' END AS status
  FROM activity_occurrences ao
  LEFT JOIN LATERAL (
    SELECT TRUE AS is_completed
    FROM public.tb_activity_registers ar
    WHERE ar.activity_id = ao.activity_id
      AND ar.deleted_at IS NULL
      AND (ar.registered_at AT TIME ZONE ao.timezone)::date = ao.event_date
    LIMIT 1
  ) ar ON TRUE
),
goal_events AS (
  SELECT
    go.activity_id AS event_id,
    'activity'::text AS event_type,
    'goal'::text AS type,
    go.name AS title,
    go.description,
    go.start_at,
    go.end_at,
    go.all_day,
    go.timezone,
    go.event_date,
    CASE WHEN go.conclusion_date IS NOT NULL AND go.event_date >= go.conclusion_date THEN TRUE ELSE FALSE END AS is_completed,
    NULL::uuid AS appointment_id,
    NULL::uuid AS professional_id,
    CASE WHEN go.conclusion_date IS NOT NULL AND go.event_date >= go.conclusion_date THEN 'completed' ELSE 'pending' END AS status
  FROM goal_occurrences go
),
appointment_scope AS (
  SELECT
    ap.id,
    ap.professional_id,
    ap.appointment_time_id,
    ap.scheduled_by,
    ap.start_of_scheduled_window,
    ap.end_of_scheduled_window,
    ap.status,
    ap.finished_at,
    at.timezone AS slot_timezone,
    rd.day_ref,
    (ap.start_of_scheduled_window AT TIME ZONE COALESCE(at.timezone, 'UTC'))::date AS event_date
  FROM ref_day rd
  CROSS JOIN my_account ma
  JOIN public.tb_appointments ap ON ap.deleted_at IS NULL
    AND (
      ma.is_admin
      OR ap.scheduled_by = ma.user_id
      OR EXISTS (
        SELECT 1 FROM public.tb_professionals p
        WHERE p.id = ap.professional_id
          AND p.deleted_at IS NULL
          AND p.user_id = ma.user_id
      )
    )
  LEFT JOIN public.tb_appointment_times at
    ON at.id = ap.appointment_time_id
   AND at.deleted_at IS NULL
),
appointments_on_day AS (
  SELECT * FROM appointment_scope WHERE event_date = day_ref
),
appointment_events AS (
  SELECT
    ap.id AS event_id,
    'appointment'::text AS event_type,
    'appointment'::text AS type,
    'Consulta agendada'::text AS title,
    NULL::text AS description,
    ap.start_of_scheduled_window AS start_at,
    ap.end_of_scheduled_window AS end_at,
    FALSE AS all_day,
    COALESCE(ap.slot_timezone, 'UTC') AS timezone,
    ap.event_date,
    (ap.status = 'completed' OR ap.finished_at IS NOT NULL) AS is_completed,
    ap.id AS appointment_id,
    ap.professional_id,
    ap.status
  FROM appointments_on_day ap
)
SELECT
  event_id,
  event_type,
  type,
  title,
  description,
  start_at,
  end_at,
  all_day,
  timezone,
  event_date,
  is_completed,
  appointment_id,
  professional_id,
  status
FROM activity_events
UNION ALL
SELECT
  event_id,
  event_type,
  type,
  title,
  description,
  start_at,
  end_at,
  all_day,
  timezone,
  event_date,
  is_completed,
  appointment_id,
  professional_id,
  status
FROM goal_events
UNION ALL
SELECT
  event_id,
  event_type,
  type,
  title,
  description,
  start_at,
  end_at,
  all_day,
  timezone,
  event_date,
  is_completed,
  appointment_id,
  professional_id,
  status
FROM appointment_events;
$$;

REVOKE ALL ON FUNCTION public.get_user_calendar_events(DATE) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_user_calendar_events(
  DATE
) TO authenticated;

CREATE VIEW public.vw_user_daily_calendar_events
WITH (security_invoker = on, security_barrier = on)
AS
SELECT * FROM public.get_user_calendar_events(CURRENT_DATE);

GRANT SELECT ON public.vw_user_daily_calendar_events TO authenticated;
REVOKE ALL ON public.vw_user_daily_calendar_events FROM anon;
