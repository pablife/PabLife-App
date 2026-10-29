-- View and function to compute monthly transfer amounts per professional
-- Uses the transfer rule that was in force when the appointment was CREATED
-- (agendada), even if the rule is inactive later.

DROP VIEW IF EXISTS public.vw_professional_monthly_transfers;
DROP FUNCTION IF EXISTS public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT
);

-- View: one row per professional per month
-- (rows exist even without appointments)
CREATE VIEW public.vw_professional_monthly_transfers
WITH (security_invoker = on, security_barrier = on)
AS
WITH bounds AS (
  SELECT
    DATE_TRUNC('month', MIN(min_date))::DATE AS min_month,
    DATE_TRUNC('month', NOW())::DATE AS max_month
  FROM (
    SELECT MIN(become_effective_at) AS min_date
    FROM public.tb_rules_professional_transfers
    UNION ALL
    SELECT MIN(start_of_scheduled_window)
    FROM public.tb_appointments
    WHERE deleted_at IS NULL
  ) AS s
),

months AS (
  SELECT
    GENERATE_SERIES(
      bounds.min_month, bounds.max_month, INTERVAL '1 month'
    )::DATE AS month_start
  FROM bounds
),

professionals AS (
  SELECT
    p.id AS professional_id,
    p.user_id,
    p.type AS professional_type,
    u.full_name AS professional_name
  FROM public.tb_professionals AS p
  LEFT JOIN public.tb_users AS u ON p.user_id = u.id AND u.deleted_at IS NULL
  WHERE p.deleted_at IS NULL
),

month_professionals AS (
  SELECT
    m.month_start,
    (m.month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS month_end,
    p.professional_id,
    p.user_id,
    p.professional_type,
    p.professional_name
  FROM months AS m
  CROSS JOIN professionals AS p
),

appointments AS (
  SELECT
    ap.id,
    ap.professional_id,
    ap.scheduled_by,
    ap.start_of_scheduled_window,
    ap.created_at
  FROM public.tb_appointments AS ap
  WHERE
    ap.deleted_at IS NULL
    AND ap.status = 'completed'
),

appointments_with_rule AS (
  SELECT
    a.*,
    r.price_per_consultation,
    r.transfer_rate
  FROM appointments AS a
  INNER JOIN public.tb_rules_professional_transfers AS r
    ON
      a.created_at >= r.become_effective_at
      AND (
        r.ceases_to_be_in_force_at IS NULL
        OR a.created_at < r.ceases_to_be_in_force_at
      )
),

appointments_agg AS (
  SELECT
    DATE_TRUNC('month', a.start_of_scheduled_window)::DATE AS month_start,
    a.professional_id,
    COUNT(*)::INTEGER AS appointments_count,
    COUNT(DISTINCT a.scheduled_by)::INTEGER AS distinct_users_count,
    SUM(a.price_per_consultation * a.transfer_rate)::NUMERIC(
      12, 2
    ) AS total_transfer_amount
  FROM appointments_with_rule AS a
  GROUP BY
    DATE_TRUNC('month', a.start_of_scheduled_window)::DATE,
    a.professional_id
)

SELECT
  mp.professional_id,
  mp.professional_name::TEXT AS professional_name,
  mp.professional_type::TEXT AS professional_type,
  mp.month_start,
  mp.month_start AS period_start,
  mp.month_end AS period_end,
  COALESCE(aa.total_transfer_amount, 0)::NUMERIC(
    12, 2
  ) AS total_transfer_amount,
  COALESCE(aa.appointments_count, 0) AS appointments_count,
  COALESCE(aa.distinct_users_count, 0) AS distinct_users_count,
  NOW() AS calculated_at
FROM month_professionals AS mp
LEFT JOIN appointments_agg AS aa
  ON
    mp.month_start = aa.month_start
    AND mp.professional_id = aa.professional_id
ORDER BY
  mp.month_start DESC, mp.professional_type ASC, mp.professional_name ASC;

GRANT SELECT ON public.vw_professional_monthly_transfers TO authenticated;
REVOKE ALL ON public.vw_professional_monthly_transfers FROM anon;

CREATE OR REPLACE FUNCTION public.get_professional_monthly_transfers(
  p_month INT DEFAULT EXTRACT(MONTH FROM CURRENT_DATE),
  p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20,
  p_type TEXT DEFAULT NULL
)
RETURNS TABLE (
  professional_id UUID,
  professional_name TEXT,
  professional_type TEXT,
  month_start DATE,
  period_start DATE,
  period_end DATE,
  appointments_count INTEGER,
  distinct_users_count INTEGER,
  total_transfer_amount NUMERIC,
  calculated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_page int := GREATEST(p_page, 1);
  v_page_size int := LEAST(GREATEST(p_page_size, 1), 50);
  v_month_start date := make_date(p_year, p_month, 1);
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.vw_professional_monthly_transfers v
  WHERE v.month_start = v_month_start
    AND (p_type IS NULL OR v.professional_type = p_type)
  ORDER BY v.month_start DESC, v.professional_type, v.professional_name
  LIMIT v_page_size
  OFFSET (v_page - 1) * v_page_size;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT
) TO authenticated;
REVOKE ALL ON FUNCTION public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT
) FROM anon;
