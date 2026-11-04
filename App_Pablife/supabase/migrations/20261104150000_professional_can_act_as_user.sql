-- O profissional também entra como usuário, com a mesma conta. As regras do
-- planner exigem is_user(), então ela passa a valer para profissional ativo.
-- As regras continuam presas à própria linha (user_id = get_my_uid()).
CREATE OR REPLACE FUNCTION public.is_user()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  current_uid uuid := public.get_my_uid();
BEGIN
  IF current_uid IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.tb_users u
    WHERE u.id = current_uid
      AND u.role IN ('user', 'professional')
      AND u.status = 'active'
  );
END;
$function$;
