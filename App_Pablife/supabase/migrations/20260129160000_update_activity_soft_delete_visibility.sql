-- Update activity policies and calendar functions to support soft delete visibility

-- tb_activities policies: allow reading soft-deleted rows for history and
-- allow updates that set deleted_at.
DROP POLICY IF EXISTS "View activity data" ON public.tb_activities;
CREATE POLICY "View activity data"
ON public.tb_activities FOR SELECT
USING (
  public.is_admin() OR (
    (public.is_user() OR public.is_professional())
    AND public.tb_activities.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Update activity data" ON public.tb_activities;
CREATE POLICY "Update activity data"
ON public.tb_activities FOR UPDATE
USING (
  public.is_admin() OR (
    public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
  )
)
WITH CHECK (
  public.is_admin() OR (
    public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
  )
);

DROP POLICY IF EXISTS "Create activity data" ON public.tb_activities;
CREATE POLICY "Create activity data"
ON public.tb_activities FOR INSERT
WITH CHECK (
  public.tb_activities.deleted_at IS NULL
  AND (
    public.is_admin() OR (
      public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
    )
  )
);

DROP POLICY IF EXISTS "Delete activity data" ON public.tb_activities;
CREATE POLICY "Delete activity data"
ON public.tb_activities FOR DELETE
USING (
  public.is_admin() OR (
    public.is_user() AND public.tb_activities.user_id = public.get_my_uid()
  )
);

-- tb_activity_registers policies: allow registers for soft-deleted activities
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
      AND a.user_id = public.get_my_uid()
  )
);

-- Update calendar events function to hide items from deleted_at date onwards
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
  JOIN public.tb_activities a ON (
    a.deleted_at IS NULL
    OR rd.day_ref < (a.deleted_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::date
  )
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
  JOIN public.tb_activities a ON (
    a.deleted_at IS NULL
    OR rd.day_ref < (a.deleted_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::date
  )
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
      AND ar.activity_date = target_date
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
        SELECT 1
        FROM public.tb_professionals p
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

-- Update calendar counts to hide items from deleted_at date onwards
CREATE OR REPLACE FUNCTION public.get_user_calendar_counts(
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE DEFAULT NULL
)
RETURNS TABLE (
  day_date DATE,
  goal_count INTEGER,
  task_count INTEGER,
  note_count INTEGER,
  appointment_count INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_start date := start_date;
  v_end date := end_date;
BEGIN
  IF v_end IS NULL THEN
    v_end := v_start + INTERVAL '10 days';
  END IF;

  IF v_end < v_start + INTERVAL '1 day' THEN
    RAISE EXCEPTION 'end_date must be at least one day after start_date';
  END IF;

  IF v_end > v_start + INTERVAL '30 days' THEN
    v_end := v_start + INTERVAL '30 days';
  END IF;

  RETURN QUERY
  WITH rng AS (
    SELECT generate_series(v_start, v_end, INTERVAL '1 day')::date AS day_ref
  ),
  my_account AS (
    SELECT
      public.get_my_uid() AS user_id,
      public.is_admin() AS is_admin,
      COALESCE(current_setting('request.jwt.claim.role', true), '') = 'service_role'
        OR current_user = 'service_role'
        OR current_user = 'postgres' AS is_service_role
  ),
  activity_base AS (
    SELECT
      a.id,
      a.user_id,
      a.type AS activity_type,
      a.all_day,
      a.due_at,
      a.timezone,
      a.activity_recurrence_rule_id,
      r.day_ref,
      (timezone(COALESCE(a.timezone, 'UTC'), r.day_ref::timestamp))::date AS day_in_activity_tz
    FROM rng r
    CROSS JOIN my_account ma
    JOIN public.tb_activities a ON (
      a.deleted_at IS NULL
      OR r.day_ref < (a.deleted_at AT TIME ZONE COALESCE(a.timezone, 'UTC'))::date
    )
      AND (
        ma.is_admin
        OR ma.is_service_role
        OR (ma.user_id IS NOT NULL AND a.user_id = ma.user_id)
      )
  ),
  non_recurring_dated AS (
    SELECT
      ab.day_ref,
      ab.activity_type,
      ab.id AS activity_id
    FROM activity_base ab
    WHERE ab.activity_recurrence_rule_id IS NULL
      AND ab.due_at IS NOT NULL
      AND ab.day_in_activity_tz = (ab.due_at AT TIME ZONE COALESCE(ab.timezone, 'UTC'))::date
  ),
  all_day_plain AS (
    SELECT
      ab.day_ref,
      ab.activity_type,
      ab.id AS activity_id
    FROM activity_base ab
    WHERE ab.activity_recurrence_rule_id IS NULL
      AND ab.all_day = TRUE
      AND ab.due_at IS NULL
  ),
  activity_recurring_on_day AS (
    SELECT
      ab.day_ref,
      ab.activity_type,
      ab.id AS activity_id,
      arr.timezone AS rule_timezone,
      (timezone(arr.timezone, ab.day_ref::timestamp))::date AS day_in_rule_tz,
      EXTRACT(DOW FROM timezone(arr.timezone, ab.day_ref::timestamp))::int AS dow_in_rule_tz,
      (arr.start_at AT TIME ZONE arr.timezone)::date AS rule_start_date
    FROM activity_base ab
    JOIN public.tb_activity_recurrence_rules arr
      ON arr.id = ab.activity_recurrence_rule_id
    WHERE arr.deleted_at IS NULL
      AND (timezone(arr.timezone, ab.day_ref::timestamp))::date >= (arr.start_at AT TIME ZONE arr.timezone)::date
      AND EXTRACT(DOW FROM timezone(arr.timezone, ab.day_ref::timestamp))::int = ANY(arr.by_week_day)
  ),
  recurring_occurrences AS (
    SELECT day_ref, activity_type, activity_id
    FROM activity_recurring_on_day
  ),
  activity_occurrences AS (
    SELECT * FROM non_recurring_dated
    UNION ALL
    SELECT * FROM all_day_plain
    UNION ALL
    SELECT * FROM recurring_occurrences
  ),
  activity_counts AS (
    SELECT day_ref AS cnt_day, activity_type AS event_kind, COUNT(DISTINCT activity_id)::integer AS total
    FROM activity_occurrences
    GROUP BY day_ref, activity_type
  ),
  appointment_scope AS (
    SELECT
      r.day_ref,
      ap.id,
      ap.professional_id,
      ap.scheduled_by,
      at.timezone AS slot_timezone,
      (ap.start_of_scheduled_window AT TIME ZONE COALESCE(at.timezone, 'UTC'))::date AS event_date
    FROM rng r
    CROSS JOIN my_account ma
    JOIN public.tb_appointments ap ON ap.deleted_at IS NULL
      AND (
        ma.is_admin
        OR ma.is_service_role
        OR (ma.user_id IS NOT NULL AND ap.scheduled_by = ma.user_id)
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
  appointment_occurrences AS (
    SELECT day_ref, 'appointment'::text AS event_kind, id AS appointment_id
    FROM appointment_scope
    WHERE event_date = day_ref
  ),
  appointment_counts AS (
    SELECT day_ref AS cnt_day, COUNT(DISTINCT appointment_id)::integer AS total
    FROM appointment_occurrences
    GROUP BY day_ref
  ),
  all_counts AS (
    SELECT cnt_day, event_kind, total FROM activity_counts
    UNION ALL
    SELECT cnt_day, 'appointment'::text AS event_kind, total FROM appointment_counts
  )
  SELECT
    d.day_ref AS day_date,
    COALESCE(SUM(ac.total) FILTER (WHERE ac.event_kind = 'goal'), 0)::integer AS goal_count,
    COALESCE(SUM(ac.total) FILTER (WHERE ac.event_kind = 'task'), 0)::integer AS task_count,
    COALESCE(SUM(ac.total) FILTER (WHERE ac.event_kind = 'note'), 0)::integer AS note_count,
    COALESCE(SUM(ac.total) FILTER (WHERE ac.event_kind = 'appointment'), 0)::integer AS appointment_count
  FROM rng d
  LEFT JOIN all_counts ac ON ac.cnt_day = d.day_ref
  GROUP BY d.day_ref
  ORDER BY d.day_ref;
END;
$$;

-- Update weekly summary to hide items from deleted_at date onwards
CREATE OR REPLACE VIEW public.vw_weekly_task_activity_summary
WITH (security_invoker = on, security_barrier = on)
AS
WITH week_context AS (
  SELECT
    (
      CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INT
    )::DATE AS week_start_date,
    (
      CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INT + 6
    )::DATE AS week_end_date
),

week_days AS (
  SELECT
    g.day_index,
    (wc.week_start_date + g.day_index)::DATE AS day_date
  FROM week_context AS wc,
    LATERAL(SELECT GENERATE_SERIES(0, 6) AS day_index) AS g
),

activities AS (
  SELECT
    id,
    user_id,
    due_at,
    all_day,
    timezone,
    activity_recurrence_rule_id,
    type,
    created_at,
    deleted_at
  FROM public.tb_activities
  WHERE
    type = 'task'
),

due_tasks AS (
  SELECT
    a.user_id,
    a.id AS activity_id,
    (TIMEZONE(COALESCE(a.timezone, 'UTC'), a.due_at))::DATE AS day_date
  FROM activities AS a
  INNER JOIN week_context AS wc ON TRUE
  WHERE
    a.due_at IS NOT NULL
    AND a.activity_recurrence_rule_id IS NULL
    AND (
      TIMEZONE(COALESCE(a.timezone, 'UTC'), a.due_at)
    )::DATE BETWEEN wc.week_start_date AND wc.week_end_date
    AND (
      a.deleted_at IS NULL
      OR (TIMEZONE(COALESCE(a.timezone, 'UTC'), a.deleted_at))::DATE
      > (TIMEZONE(COALESCE(a.timezone, 'UTC'), a.due_at))::DATE
    )
),

all_day_tasks AS (
  SELECT
    a.user_id,
    a.id AS activity_id,
    wd.day_date
  FROM activities AS a
  INNER JOIN week_days AS wd ON TRUE
  WHERE
    a.all_day = TRUE
    AND a.due_at IS NULL
    AND a.activity_recurrence_rule_id IS NULL
    AND (
      a.deleted_at IS NULL
      OR wd.day_date
      < (TIMEZONE(COALESCE(a.timezone, 'UTC'), a.deleted_at))::DATE
    )
),

recurring_tasks AS (
  SELECT
    a.user_id,
    a.id AS activity_id,
    wd.day_date
  FROM activities AS a
  INNER JOIN public.tb_activity_recurrence_rules AS arr
    ON a.activity_recurrence_rule_id = arr.id
  INNER JOIN week_days AS wd ON TRUE
  WHERE
    arr.deleted_at IS NULL
    AND wd.day_index = ANY(arr.by_week_day)
    AND wd.day_date >= (TIMEZONE(arr.timezone, arr.start_at))::DATE
    AND (
      a.deleted_at IS NULL
      OR wd.day_date
      < (TIMEZONE(COALESCE(a.timezone, 'UTC'), a.deleted_at))::DATE
    )
),

task_occurrences AS (
  SELECT * FROM due_tasks
  UNION ALL
  SELECT * FROM all_day_tasks
  UNION ALL
  SELECT * FROM recurring_tasks
),

daily_totals AS (
  SELECT
    user_id,
    day_date,
    COUNT(DISTINCT activity_id) AS total_tasks
  FROM task_occurrences
  GROUP BY user_id, day_date
),

daily_completions AS (
  SELECT
    tocc.user_id,
    tocc.day_date,
    COUNT(ar.id) AS completed_tasks
  FROM task_occurrences AS tocc
  INNER JOIN public.tb_activity_registers AS ar
    ON
      tocc.activity_id = ar.activity_id
      AND ar.deleted_at IS NULL
      AND ar.activity_date = tocc.day_date
  GROUP BY tocc.user_id, tocc.day_date
),

-- escopo agora baseado em todos os usuários válidos para garantir linhas vazias
user_scope AS (
  SELECT id AS user_id
  FROM public.tb_users
  WHERE
    deleted_at IS NULL
    AND status IN ('active', 'deactivated')
),

day_matrix AS (
  SELECT
    us.user_id,
    wd.day_index,
    wd.day_date,
    COALESCE(dt.total_tasks, 0) AS total_tasks,
    COALESCE(dc.completed_tasks, 0) AS completed_tasks
  FROM user_scope AS us
  INNER JOIN week_days AS wd ON TRUE
  LEFT JOIN daily_totals AS dt
    ON us.user_id = dt.user_id AND wd.day_date = dt.day_date
  LEFT JOIN daily_completions AS dc
    ON us.user_id = dc.user_id AND wd.day_date = dc.day_date
),

-- métricas de tarefas (percentual concluído no dia atual)
tasks_today AS (
  SELECT
    dm.user_id,
    SUM(
      CASE WHEN dm.day_date = CURRENT_DATE THEN dm.total_tasks ELSE 0 END
    ) AS total_today,
    SUM(
      CASE WHEN dm.day_date = CURRENT_DATE THEN dm.completed_tasks ELSE 0 END
    ) AS completed_today
  FROM day_matrix AS dm
  GROUP BY dm.user_id
),

tasks_json AS (
  SELECT
    tt.user_id,
    JSONB_BUILD_ARRAY(
      JSONB_BUILD_OBJECT(
        'percentage',
        CASE
          WHEN
            tt.total_today > 0
            THEN ROUND((tt.completed_today::NUMERIC / tt.total_today) * 100, 2)
          ELSE 0
        END
      )
    ) AS tasks
  FROM tasks_today AS tt
),

-- metas (goals) com percentual de prazo decorrido, descrição e prazo final
goals_raw AS (
  SELECT
    a.user_id,
    a.id AS goal_id,
    a.name,
    a.description,
    a.created_at,
    a.due_at,
    CASE
      WHEN a.due_at IS NULL OR a.due_at <= a.created_at THEN 0
      ELSE LEAST(100, GREATEST(
        0,
        ROUND(
          (
            (
              EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - a.created_at))
              / NULLIF(EXTRACT(EPOCH FROM (a.due_at - a.created_at)), 0)
            )
            * 100
          )::NUMERIC,
          2
        )
      ))
    END AS percentage
  FROM public.tb_activities AS a
  WHERE
    a.type = 'goal'
    AND a.deleted_at IS NULL
),

goals_json AS (
  SELECT
    gr.user_id,
    JSONB_AGG(
      JSONB_BUILD_OBJECT(
        'goal_id', gr.goal_id,
        'name', gr.name,
        'description', gr.description,
        'due_at', gr.due_at,
        'percentage', gr.percentage
      )
    ) AS goals
  FROM goals_raw AS gr
  GROUP BY gr.user_id
)

SELECT
  dm.user_id,
  wc.week_start_date,
  ARRAY_AGG(
    ARRAY[dm.total_tasks, dm.completed_tasks]::INTEGER []
    ORDER BY dm.day_index
  ) AS week_day_counts,
  COALESCE(tj.tasks, '[{"percentage":0}]'::JSONB) AS tasks,
  COALESCE(gj.goals, '[]'::JSONB) AS goals
FROM day_matrix AS dm
INNER JOIN week_context AS wc ON TRUE
LEFT JOIN tasks_json AS tj ON dm.user_id = tj.user_id
LEFT JOIN goals_json AS gj ON dm.user_id = gj.user_id
GROUP BY dm.user_id, wc.week_start_date, tj.tasks, gj.goals
ORDER BY dm.user_id;
