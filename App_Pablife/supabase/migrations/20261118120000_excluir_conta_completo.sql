-- Excluir conta: apaga TODOS os dados da Saúde da Mulher e o apelido.
--
-- A regra anterior apagava só check-ins e o perfil do ciclo. Ficavam no banco
-- registros do ciclo (tb_women_health_logs), o diário, as gestações e os
-- registros da gestação. Também ficava o "como prefere ser chamada"
-- (preferred_name), que a função delete-account não limpa.
--
-- Só roda quando a conta é excluída (deleted_at passa de vazio para preenchido).

CREATE OR REPLACE FUNCTION public.erase_women_health_on_account_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    DELETE FROM public.tb_women_health_check_ins WHERE user_id = NEW.id;
    DELETE FROM public.tb_women_health_profiles WHERE user_id = NEW.id;
    DELETE FROM public.tb_women_health_logs WHERE user_id = NEW.id;
    DELETE FROM public.tb_women_health_diary_entries WHERE user_id = NEW.id;
    -- tb_pregnancy_records some junto (ON DELETE CASCADE da gestação);
    -- o segundo DELETE pega registros soltos, se houver.
    DELETE FROM public.tb_pregnancies WHERE user_id = NEW.id;
    DELETE FROM public.tb_pregnancy_records WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.clear_preferred_name_on_account_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    NEW.preferred_name := NULL;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS clear_preferred_name_on_account_delete ON public.tb_users;
CREATE TRIGGER clear_preferred_name_on_account_delete
  BEFORE UPDATE OF deleted_at ON public.tb_users
  FOR EACH ROW EXECUTE FUNCTION public.clear_preferred_name_on_account_delete();

REVOKE ALL ON FUNCTION public.clear_preferred_name_on_account_delete() FROM PUBLIC, anon, authenticated;
