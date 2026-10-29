-- View e função para contagem diária de eventos (atividades e consultas)
-- por tipo
-- Respeita RLS e filtra pelo usuário atual (ou admin/profissional responsável)

DROP VIEW IF EXISTS public.vw_user_calendar_counts;
DROP FUNCTION IF EXISTS public.get_user_calendar_counts(DATE, DATE);

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
    JOIN public.tb_activities a ON a.deleted_at IS NULL
      AND (ma.is_admin OR ma.is_service_role OR (ma.user_id IS NOT NULL AND a.user_id = ma.user_id))
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

REVOKE ALL ON FUNCTION public.get_user_calendar_counts(DATE, DATE) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_user_calendar_counts(
  DATE, DATE
) TO authenticated;

-- View para facilitar consumo padrão (próximos 10 dias a partir de hoje)
CREATE VIEW public.vw_user_calendar_counts
WITH (security_invoker = on, security_barrier = on)
AS
SELECT * FROM public.get_user_calendar_counts(CURRENT_DATE, NULL);

GRANT SELECT ON public.vw_user_calendar_counts TO authenticated;
REVOKE ALL ON public.vw_user_calendar_counts FROM anon;
