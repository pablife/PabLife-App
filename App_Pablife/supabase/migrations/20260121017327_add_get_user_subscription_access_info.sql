CREATE OR REPLACE FUNCTION public.get_user_subscription_access_info()
RETURNS TABLE (
  access_type TEXT,
  user_id UUID,
  consultations_total INTEGER,
  consultations_used INTEGER,
  consultations_remaining INTEGER
)
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID;
  v_created_at TIMESTAMPTZ;
  v_min_start TIMESTAMPTZ;
  v_max_end TIMESTAMPTZ;
  v_total INTEGER := 0;
  v_used INTEGER := 0;
  v_valid_count INTEGER := 0;
  v_access TEXT := 'free';
BEGIN
  v_user_id := public.get_my_uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  SELECT u.created_at
  INTO v_created_at
  FROM public.tb_users AS u
  WHERE u.id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  SELECT
    COALESCE(SUM(sp.consultations), 0) AS total,
    MIN(us.start_date) AS min_start,
    MAX(us.end_date) AS max_end,
    COUNT(*) AS valid_count
  INTO v_total, v_min_start, v_max_end, v_valid_count
  FROM public.tb_user_subscriptions AS us
  JOIN public.tb_subscription_plans AS sp ON sp.id = us.plan_id
  WHERE us.user_id = v_user_id
    AND us.status IN ('active', 'cancelled')
    AND us.start_date IS NOT NULL
    AND us.end_date IS NOT NULL
    AND now() >= us.start_date
    AND now() <= us.end_date;

  IF v_valid_count > 0 THEN
    v_access := 'subscriber';
  ELSIF now() < v_created_at + INTERVAL '7 days' THEN
    v_access := 'trial';
  ELSE
    v_access := 'free';
  END IF;

  IF v_min_start IS NOT NULL AND v_max_end IS NOT NULL THEN
    SELECT COUNT(*)
    INTO v_used
    FROM public.tb_appointments AS ap
    WHERE ap.scheduled_by = v_user_id
      AND ap.status = 'completed'
      AND ap.deleted_at IS NULL
      AND ap.created_at >= v_min_start
      AND ap.created_at <= v_max_end;
  END IF;

  IF v_access NOT IN ('free', 'trial', 'subscriber') THEN
    RAISE EXCEPTION 'Invalid access_type';
  END IF;

  RETURN QUERY SELECT
    v_access,
    v_user_id,
    v_total,
    v_used,
    GREATEST(v_total - v_used, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_subscription_access_info() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_subscription_access_info() TO authenticated;
