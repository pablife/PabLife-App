-- Sincroniza all_day em tb_activities a partir de by_week_day da regra
-- de recorrência.

-- Função auxiliar: dado um rule_id, ajusta all_day das atividades vinculadas
DROP FUNCTION IF EXISTS public.sync_activity_all_day(UUID);
CREATE OR REPLACE FUNCTION public.sync_activity_all_day(rule_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_full_week boolean;
BEGIN
  SELECT by_week_day @> ARRAY[0,1,2,3,4,5,6]::smallint[]
    INTO v_is_full_week
  FROM public.tb_activity_recurrence_rules
  WHERE id = rule_id
    AND deleted_at IS NULL;

  UPDATE public.tb_activities a
     SET all_day = COALESCE(v_is_full_week, FALSE),
         updated_at = NOW()
   WHERE a.activity_recurrence_rule_id = rule_id;
END;
$$;

-- Função usada pelo trigger de tb_activities
DROP FUNCTION IF EXISTS public.set_all_day_from_rule();
CREATE OR REPLACE FUNCTION public.set_all_day_from_rule()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_full_week boolean;
BEGIN
  SELECT by_week_day @> ARRAY[0,1,2,3,4,5,6]::smallint[]
    INTO v_is_full_week
  FROM public.tb_activity_recurrence_rules
  WHERE id = NEW.activity_recurrence_rule_id
    AND deleted_at IS NULL;

  NEW.all_day := COALESCE(v_is_full_week, FALSE);
  RETURN NEW;
END;
$$;

-- Trigger BEFORE INSERT/UPDATE em tb_activities para definir all_day
-- conforme a regra
DROP TRIGGER IF EXISTS trg_set_all_day_from_rule ON public.tb_activities;
CREATE TRIGGER trg_set_all_day_from_rule
BEFORE INSERT OR UPDATE OF activity_recurrence_rule_id ON public.tb_activities
FOR EACH ROW
WHEN (new.activity_recurrence_rule_id IS NOT NULL)
EXECUTE FUNCTION public.set_all_day_from_rule();

-- Função usada pelo trigger da tabela de regras
DROP FUNCTION IF EXISTS public.update_all_day_from_rule_change();
CREATE OR REPLACE FUNCTION public.update_all_day_from_rule_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM public.sync_activity_all_day(NEW.id);
  RETURN NEW;
END;
$$;

-- Trigger AFTER INSERT/UPDATE em tb_activity_recurrence_rules para sincronizar
--  atividades existentes
DROP TRIGGER IF EXISTS trg_sync_all_day_on_rule_change
ON public.tb_activity_recurrence_rules;
CREATE TRIGGER trg_sync_all_day_on_rule_change
AFTER INSERT OR UPDATE OF by_week_day ON public.tb_activity_recurrence_rules
FOR EACH ROW
WHEN (new.id IS NOT NULL)
EXECUTE FUNCTION public.update_all_day_from_rule_change();
