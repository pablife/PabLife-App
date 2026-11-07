-- Visual escolhido (Pablife ou Saúde da Mulher), guardado no cadastro para
-- valer em qualquer aparelho e na web. Fica numa tabela separada que só a
-- própria pessoa lê: nem o profissional que a atende nem o painel veem.

CREATE TABLE IF NOT EXISTS public.tb_user_preferences (
  user_id uuid PRIMARY KEY REFERENCES public.tb_users (id) ON DELETE CASCADE,
  app_theme text NOT NULL DEFAULT 'pablife'
    CHECK (app_theme IN ('pablife', 'saude_mulher')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS set_updated_at_trigger_tb_user_preferences ON public.tb_user_preferences;
CREATE TRIGGER set_updated_at_trigger_tb_user_preferences
  BEFORE UPDATE ON public.tb_user_preferences
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.tb_user_preferences ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.tb_user_preferences FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_user_preferences TO authenticated;

DROP POLICY IF EXISTS "Own preferences" ON public.tb_user_preferences;
CREATE POLICY "Own preferences"
  ON public.tb_user_preferences
  FOR ALL
  TO authenticated
  USING (user_id = public.get_my_uid())
  WITH CHECK (user_id = public.get_my_uid());

-- Quem já usa a Saúde da Mulher continua nela.
INSERT INTO public.tb_user_preferences (user_id, app_theme)
SELECT w.user_id, 'saude_mulher'
FROM public.tb_women_health_profiles w
JOIN public.tb_users u ON u.id = w.user_id AND u.deleted_at IS NULL
WHERE w.trail IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

-- Conta excluída: a preferência some junto.
CREATE OR REPLACE FUNCTION public.erase_preferences_on_account_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    DELETE FROM public.tb_user_preferences WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.erase_preferences_on_account_delete() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS erase_preferences_on_account_delete ON public.tb_users;
CREATE TRIGGER erase_preferences_on_account_delete
  AFTER UPDATE OF deleted_at ON public.tb_users
  FOR EACH ROW EXECUTE FUNCTION public.erase_preferences_on_account_delete();
