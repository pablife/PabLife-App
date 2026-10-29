DROP VIEW IF EXISTS public.vw_weekly_appointment_activity_summary;

CREATE VIEW public.vw_weekly_appointment_activity_summary AS
WITH week_context AS (
  SELECT
    (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INT)::DATE
    AS week_start_date,
    (CURRENT_DATE - EXTRACT(DOW FROM CURRENT_DATE)::INT + 6)::DATE
    AS week_end_date
),

week_days AS (
  SELECT
    g.day_index,
    (wc.week_start_date + g.day_index)::DATE AS day_date
  FROM week_context AS wc,
    LATERAL(SELECT GENERATE_SERIES(0, 6) AS day_index) AS g
),

appointments AS (
  SELECT
    id,
    professional_id,
    start_of_scheduled_window,
    end_of_scheduled_window,
    finished_at,
    deleted_at
  FROM public.tb_appointments
  WHERE deleted_at IS NULL
),

scheduled_appointments AS (
  SELECT
    a.professional_id,
    a.id AS appointment_id,
    (TIMEZONE('America/Sao_Paulo', a.start_of_scheduled_window))::DATE
    AS day_date,
    a.finished_at
  FROM appointments AS a
  INNER JOIN week_context AS wc ON TRUE
  WHERE
    (
      TIMEZONE('America/Sao_Paulo', a.start_of_scheduled_window)
    )::DATE BETWEEN wc.week_start_date AND wc.week_end_date
),

daily_totals AS (
  SELECT
    professional_id,
    day_date,
    COUNT(DISTINCT appointment_id) AS total_appointments
  FROM scheduled_appointments
  GROUP BY professional_id, day_date
),

daily_completions AS (
  SELECT
    professional_id,
    day_date,
    COUNT(DISTINCT appointment_id) AS completed_appointments
  FROM scheduled_appointments
  WHERE finished_at IS NOT NULL
  GROUP BY professional_id, day_date
),

professional_scope AS (
  SELECT DISTINCT professional_id FROM scheduled_appointments
),

day_matrix AS (
  SELECT
    ps.professional_id,
    wd.day_index,
    wd.day_date,
    COALESCE(dt.total_appointments, 0) AS total_appointments,
    COALESCE(dc.completed_appointments, 0) AS completed_appointments
  FROM professional_scope AS ps
  INNER JOIN week_days AS wd ON TRUE
  LEFT JOIN daily_totals AS dt
    ON ps.professional_id = dt.professional_id AND wd.day_date = dt.day_date
  LEFT JOIN daily_completions AS dc
    ON ps.professional_id = dc.professional_id AND wd.day_date = dc.day_date
)

SELECT
  dm.professional_id,
  wc.week_start_date,
  ARRAY_AGG(
    ARRAY[dm.total_appointments, dm.completed_appointments]::INTEGER []
    ORDER BY dm.day_index
  ) AS week_day_counts
FROM day_matrix AS dm
INNER JOIN week_context AS wc ON TRUE
GROUP BY dm.professional_id, wc.week_start_date
ORDER BY dm.professional_id;

GRANT SELECT ON public.vw_weekly_appointment_activity_summary TO authenticated;
REVOKE ALL ON public.vw_weekly_appointment_activity_summary FROM anon;
