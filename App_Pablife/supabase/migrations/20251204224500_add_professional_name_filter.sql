-- Add optional professional name filter to get_professional_monthly_transfers

DROP FUNCTION IF EXISTS public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT, TEXT
);
DROP FUNCTION IF EXISTS public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT
);

CREATE OR REPLACE FUNCTION public.get_professional_monthly_transfers(
  p_month INT DEFAULT EXTRACT(MONTH FROM CURRENT_DATE),
  p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20,
  p_type TEXT DEFAULT NULL,
  p_professional_name TEXT DEFAULT NULL
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
    AND (
      p_professional_name IS NULL
      OR v.professional_name ILIKE '%' || p_professional_name || '%'
    )
  ORDER BY v.month_start DESC, v.professional_type, v.professional_name
  LIMIT v_page_size
  OFFSET (v_page - 1) * v_page_size;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT, TEXT
) TO authenticated;
REVOKE ALL ON FUNCTION public.get_professional_monthly_transfers(
  INT, INT, INT, INT, TEXT, TEXT
) FROM anon;
