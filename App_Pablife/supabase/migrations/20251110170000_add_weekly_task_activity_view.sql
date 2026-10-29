-- Ajusta a view para retornar linhas para todos os usuários,
-- mesmo sem tarefas/goals

DROP VIEW IF EXISTS public.vw_weekly_task_activity_summary;

CREATE VIEW public.vw_weekly_task_activity_summary
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
    created_at
  FROM public.tb_activities
  WHERE
    type = 'task'
    AND deleted_at IS NULL
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
      AND ar.registered_at::DATE = tocc.day_date
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

GRANT SELECT ON public.vw_weekly_task_activity_summary TO authenticated;
REVOKE ALL ON public.vw_weekly_task_activity_summary FROM anon;
