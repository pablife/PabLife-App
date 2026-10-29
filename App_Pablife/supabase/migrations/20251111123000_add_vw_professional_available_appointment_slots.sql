DROP VIEW IF EXISTS public.vw_professional_available_appointment_slots;

CREATE VIEW public.vw_professional_available_appointment_slots AS
WITH params AS (
  SELECT 180 AS future_day_horizon -- days ahead to expand recurring slots
),

my_account AS (
  SELECT public.get_my_uid() AS user_id
),

professional_data AS (
  SELECT
    p.id AS professional_id,
    p.type AS professional_type,
    u.full_name AS professional_full_name,
    u.email::TEXT AS professional_email
  FROM public.tb_professionals AS p
  INNER JOIN public.tb_users AS u ON p.user_id = u.id
  WHERE
    p.deleted_at IS NULL
    AND u.deleted_at IS NULL
),

explicit_slots AS (
  SELECT
    t.id AS appointment_time_id,
    t.appointment_recurrence_rule_id,
    pd.professional_id,
    pd.professional_type,
    pd.professional_full_name,
    pd.professional_email,
    t.start_time_at,
    t.finish_time_at,
    t.timezone,
    t.due_at AS slot_date,
    (
      (
        t.due_at + t.start_time_at
      ) AT TIME ZONE COALESCE(t.timezone, 'UTC')
    ) AS slot_start_at,
    (
      (
        t.due_at + t.finish_time_at
      ) AT TIME ZONE COALESCE(t.timezone, 'UTC')
    ) AS slot_finish_at
  FROM public.tb_appointment_times AS t
  INNER JOIN professional_data AS pd ON t.professional_id = pd.professional_id
  WHERE
    t.deleted_at IS NULL
    AND t.due_at IS NOT NULL
    AND t.appointment_recurrence_rule_id IS NULL
),

recurring_sources AS (
  SELECT
    t.id,
    t.professional_id,
    t.start_time_at,
    t.finish_time_at,
    t.timezone,
    arr.id AS appointment_recurrence_rule_id,
    arr.week_select,
    arr.end_at,
    TIMEZONE(arr.timezone, arr.start_at)::DATE AS recurrence_start_date,
    TIMEZONE(arr.timezone, arr.end_at)::DATE AS recurrence_end_date
  FROM public.tb_appointment_times AS t
  INNER JOIN public.tb_appointment_recurrence_rules AS arr
    ON t.appointment_recurrence_rule_id = arr.id
  WHERE
    t.deleted_at IS NULL
    AND arr.deleted_at IS NULL
),

recurring_slots AS (
  SELECT
    rs.id AS appointment_time_id,
    rs.appointment_recurrence_rule_id,
    pd.professional_id,
    pd.professional_type,
    pd.professional_full_name,
    pd.professional_email,
    rs.start_time_at,
    rs.finish_time_at,
    rs.timezone,
    future_days.slot_date,
    ((future_days.slot_date + rs.start_time_at) AT TIME ZONE rs.timezone)
    AS slot_start_at,
    ((future_days.slot_date + rs.finish_time_at) AT TIME ZONE rs.timezone)
    AS slot_finish_at
  FROM recurring_sources AS rs
  INNER JOIN professional_data AS pd ON rs.professional_id = pd.professional_id
  INNER JOIN params ON TRUE
  INNER JOIN LATERAL (
    SELECT (CURRENT_DATE + g.day_offset) AS slot_date
    FROM GENERATE_SERIES(0, params.future_day_horizon) AS g (day_offset)
    WHERE
      (CURRENT_DATE + g.day_offset) >= rs.recurrence_start_date
      AND (
        rs.recurrence_end_date IS NULL
        OR (CURRENT_DATE + g.day_offset) <= rs.recurrence_end_date
      )
      AND EXTRACT(DOW FROM (CURRENT_DATE + g.day_offset))::INT = rs.week_select
  ) AS future_days ON TRUE
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_appointment_times AS t2
    WHERE
      t2.deleted_at IS NULL
      AND t2.appointment_recurrence_rule_id IS NULL
      AND t2.professional_id = rs.professional_id
      AND t2.due_at = future_days.slot_date
      AND t2.start_time_at = rs.start_time_at
      AND t2.finish_time_at = rs.finish_time_at
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.tb_appointment_recurrence_exceptions AS ex
    WHERE
      ex.deleted_at IS NULL
      AND ex.appointment_time_id = rs.id
      AND ex.slot_date = future_days.slot_date
  )
),

all_slots AS (
  SELECT * FROM explicit_slots
  UNION ALL
  SELECT * FROM recurring_slots
),

slots_with_booking AS (
  SELECT
    s.*,
    a.id AS appointment_id,
    a.scheduled_by AS appointment_user_id,
    my.user_id AS current_user_id
  FROM all_slots AS s
  CROSS JOIN my_account AS my
  LEFT JOIN LATERAL (
    SELECT
      ap.id,
      ap.scheduled_by
    FROM public.tb_appointments AS ap
    WHERE
      ap.appointment_time_id = s.appointment_time_id
      AND ap.deleted_at IS NULL
      AND (TIMEZONE(s.timezone, ap.start_of_scheduled_window))::DATE
      = s.slot_date
    ORDER BY ap.start_of_scheduled_window DESC
    LIMIT 1
  ) AS a ON TRUE
  WHERE
    (a.id IS NULL OR (my.user_id IS NOT NULL AND a.scheduled_by = my.user_id))
)

SELECT
  swb.professional_id,
  swb.appointment_time_id,
  swb.appointment_recurrence_rule_id,
  swb.slot_date,
  EXTRACT(DAY FROM swb.slot_date)::INT AS slot_day,
  EXTRACT(MONTH FROM swb.slot_date)::INT AS slot_month,
  swb.start_time_at,
  swb.finish_time_at,
  swb.timezone,
  swb.slot_start_at,
  swb.slot_finish_at,
  swb.professional_type,
  swb.professional_full_name,
  swb.professional_email,
  (swb.appointment_id IS NOT NULL) AS is_my_appointment
FROM slots_with_booking AS swb;

GRANT SELECT ON public.vw_professional_available_appointment_slots
TO authenticated;
REVOKE ALL ON public.vw_professional_available_appointment_slots FROM anon;
