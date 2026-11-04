-- Fecha os caminhos para uma conta comum virar administradora ou profissional
-- aprovada, e o resumo semanal que ignorava a RLS.

-- 1. Criar conta só pela função create-account (que usa service_role).
REVOKE ALL ON FUNCTION public.create_user_account(uuid, character varying, extensions.citext, character varying, character varying, boolean, character varying, character varying, character varying, character varying) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.create_user_account(uuid, character varying, extensions.citext, character varying, character varying, boolean, character varying, character varying, character varying, character varying, text) FROM PUBLIC, anon, authenticated;

-- 2. Papel, situação e aprovação só mudam pelo administrador ou pelo servidor.
-- As regras de RLS deixam a pessoa alterar a própria linha inteira; aqui ficam
-- de fora os campos que dão acesso. Funções do servidor (service_role) e
-- SECURITY DEFINER não passam por current_user authenticated/anon.
CREATE OR REPLACE FUNCTION public.protect_user_privileged_columns()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF (NEW.role IS DISTINCT FROM OLD.role
      OR NEW.status IS DISTINCT FROM OLD.status
      OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at)
     AND current_user IN ('authenticated', 'anon')
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_professional_privileged_columns()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF (NEW.validation_status IS DISTINCT FROM OLD.validation_status
      OR NEW.user_id IS DISTINCT FROM OLD.user_id
      OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at)
     AND current_user IN ('authenticated', 'anon')
     AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER protect_user_privileged_columns
  BEFORE UPDATE ON public.tb_users
  FOR EACH ROW EXECUTE FUNCTION public.protect_user_privileged_columns();

CREATE TRIGGER protect_professional_privileged_columns
  BEFORE UPDATE ON public.tb_professionals
  FOR EACH ROW EXECUTE FUNCTION public.protect_professional_privileged_columns();

REVOKE ALL ON FUNCTION public.protect_user_privileged_columns() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.protect_professional_privileged_columns() FROM PUBLIC, anon, authenticated;

-- 3. O resumo semanal passa a respeitar a RLS de quem consulta.
ALTER VIEW public.vw_weekly_task_activity_summary SET (security_invoker = on);
ALTER VIEW public.vw_weekly_appointment_activity_summary SET (security_invoker = on);

-- 4. Funções que aceitam o id de outra conta e o app não usa.
REVOKE ALL ON FUNCTION public.get_user_trial_info(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.user_has_active_subscription(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.user_has_active_trial(uuid) FROM PUBLIC, anon, authenticated;

-- 5. Só faz sentido com login (ela mesma já exige profissional).
REVOKE ALL ON FUNCTION public.soft_delete_appointment_time(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.soft_delete_appointment_time(uuid) TO authenticated;
