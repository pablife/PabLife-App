CREATE OR REPLACE FUNCTION public.get_user_consultation_balances()
RETURNS TABLE (
  consultations_remaining INTEGER,
  expires_at TIMESTAMPTZ,
  start_date TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_min_start TIMESTAMPTZ;
  v_max_end TIMESTAMPTZ;
  v_used INTEGER := 0;
BEGIN
  v_user_id := public.get_my_uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  WITH valid_subs AS (
    SELECT
      us.id,
      us.start_date,
      us.end_date,
      us.created_at,
      sp.consultations::integer AS consultations
    FROM public.tb_user_subscriptions AS us
    JOIN public.tb_subscription_plans AS sp ON sp.id = us.plan_id
    WHERE us.user_id = v_user_id
      AND us.status IN ('active', 'cancelled')
      AND us.start_date IS NOT NULL
      AND us.end_date IS NOT NULL
      AND now() >= us.start_date
      AND now() <= us.end_date
  )
  SELECT
    MIN(vs.start_date),
    MAX(vs.end_date)
  INTO v_min_start, v_max_end
  FROM valid_subs vs;

  IF v_min_start IS NOT NULL AND v_max_end IS NOT NULL THEN
    SELECT COUNT(*)::integer
    INTO v_used
    FROM public.tb_appointments AS ap
    WHERE ap.scheduled_by = v_user_id
      AND ap.status = 'completed'
      AND ap.deleted_at IS NULL
      AND ap.created_at >= v_min_start
      AND ap.created_at <= v_max_end;
  END IF;

  RETURN QUERY
  WITH valid_subs AS (
    SELECT
      us.id,
      us.start_date,
      us.end_date,
      us.created_at,
      sp.consultations::integer AS consultations
    FROM public.tb_user_subscriptions AS us
    JOIN public.tb_subscription_plans AS sp ON sp.id = us.plan_id
    WHERE us.user_id = v_user_id
      AND us.status IN ('active', 'cancelled')
      AND us.start_date IS NOT NULL
      AND us.end_date IS NOT NULL
      AND now() >= us.start_date
      AND now() <= us.end_date
  ),
  ordered AS (
    SELECT
      vs.id,
      vs.start_date AS sub_start_date,
      vs.end_date   AS sub_end_date,
      vs.created_at AS sub_created_at,
      vs.consultations,
      SUM(vs.consultations) OVER (
        ORDER BY vs.start_date, vs.created_at, vs.id
      ) AS cumulative_consultations
    FROM valid_subs vs
  )
  SELECT
    (
      GREATEST(
        o.consultations::bigint - GREATEST(
          v_used::bigint - (o.cumulative_consultations - o.consultations::bigint),
          0::bigint
        ),
        0::bigint
      )
    )::integer AS consultations_remaining,
    o.sub_end_date AS expires_at,
    o.sub_start_date AS start_date
  FROM ordered o
  WHERE
    GREATEST(
      o.consultations::bigint - GREATEST(
        v_used::bigint - (o.cumulative_consultations - o.consultations::bigint),
        0::bigint
      ),
      0::bigint
    ) > 0
  ORDER BY o.sub_start_date, o.sub_end_date;

END;
$$;

REVOKE ALL ON FUNCTION public.get_user_consultation_balances() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_consultation_balances()
TO authenticated;
