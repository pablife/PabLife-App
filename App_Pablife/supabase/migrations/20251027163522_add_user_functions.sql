CREATE OR REPLACE FUNCTION public.validate_user_email(
  user_email EXTENSIONS.CITEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  email_exists boolean := false;
BEGIN
  IF user_email IS NULL OR trim(user_email::text) = '' THEN
    RAISE EXCEPTION 'Email parameter cannot be null or empty';
  END IF;

  SELECT EXISTS(SELECT 1 FROM public.tb_users WHERE email = user_email)
    INTO email_exists;

  RETURN email_exists;
END;
$$;

REVOKE ALL ON FUNCTION public.validate_user_email(
  EXTENSIONS.CITEXT
) FROM public;
GRANT EXECUTE ON FUNCTION public.validate_user_email(EXTENSIONS.CITEXT) TO anon,
authenticated;

CREATE OR REPLACE FUNCTION public.is_user()
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  current_uid uuid := public.get_my_uid();
BEGIN
  IF current_uid IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.tb_users u
    WHERE u.id = current_uid AND u.role = 'user' AND u.status = 'active'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.is_user() FROM public;
GRANT EXECUTE ON FUNCTION public.is_user() TO authenticated;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  current_uid uuid := public.get_my_uid();
BEGIN
  IF current_uid IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.tb_users u
    WHERE u.id = current_uid AND u.role = 'admin' AND u.status = 'active'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.is_professional()
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  current_uid uuid := public.get_my_uid();
BEGIN
  IF current_uid IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.tb_users u
    WHERE u.id = current_uid AND u.role = 'professional' AND u.status = 'active'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.is_professional() FROM public;
GRANT EXECUTE ON FUNCTION public.is_professional() TO authenticated;
