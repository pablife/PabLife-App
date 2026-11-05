-- Assinatura de calendário: cada pessoa recebe um link secreto para ver o
-- PabLife no Calendário da Apple (ou Google, Outlook). São dois links
-- separados: planner (tarefas, metas, consultas) e saúde da mulher (trilhas).
--
-- O banco guarda só o hash do link. Quem lê o banco não consegue montar o link,
-- e por isso gerar de novo troca o link antigo, que para de funcionar.

CREATE TABLE public.tb_calendar_feeds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.tb_users (id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('planner', 'women_health')),
  token_hash text NOT NULL UNIQUE,
  include_tasks boolean NOT NULL DEFAULT true,
  include_goals boolean NOT NULL DEFAULT true,
  include_appointments boolean NOT NULL DEFAULT true,
  -- Saúde da mulher: troca "Menstruação", "Fértil" etc. por um nome neutro.
  discreet_titles boolean NOT NULL DEFAULT false,
  last_fetched_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, kind)
);

CREATE TRIGGER set_updated_at_trigger_tb_calendar_feeds
  BEFORE UPDATE ON public.tb_calendar_feeds
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.tb_calendar_feeds ENABLE ROW LEVEL SECURITY;

-- O app vê e ajusta as opções, mas nunca o hash. Criar e trocar o link só pela
-- função abaixo.
REVOKE ALL ON public.tb_calendar_feeds FROM PUBLIC, anon, authenticated;
GRANT SELECT (
  id, user_id, kind, include_tasks, include_goals, include_appointments,
  discreet_titles, last_fetched_at, created_at, updated_at
) ON public.tb_calendar_feeds TO authenticated;
GRANT UPDATE (
  include_tasks, include_goals, include_appointments, discreet_titles
) ON public.tb_calendar_feeds TO authenticated;
GRANT DELETE ON public.tb_calendar_feeds TO authenticated;

CREATE POLICY "Own calendar feeds: read"
  ON public.tb_calendar_feeds
  FOR SELECT
  TO authenticated
  USING (user_id = public.get_my_uid());

CREATE POLICY "Own calendar feeds: update"
  ON public.tb_calendar_feeds
  FOR UPDATE
  TO authenticated
  USING (user_id = public.get_my_uid())
  WITH CHECK (user_id = public.get_my_uid());

CREATE POLICY "Own calendar feeds: delete"
  ON public.tb_calendar_feeds
  FOR DELETE
  TO authenticated
  USING (user_id = public.get_my_uid());

-- Cria o link, ou troca o atual. O link só é devolvido aqui, uma única vez.
CREATE OR REPLACE FUNCTION public.connect_calendar_feed(p_kind text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_user_id uuid := public.get_my_uid();
  v_token text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Sessão inválida' USING ERRCODE = '42501';
  END IF;

  IF p_kind NOT IN ('planner', 'women_health') THEN
    RAISE EXCEPTION 'Tipo de calendário inválido' USING ERRCODE = '22023';
  END IF;

  -- Saúde da mulher só sai do app se a usuária já tiver aceitado a trilha.
  IF p_kind = 'women_health' AND NOT EXISTS (
    SELECT 1
    FROM public.tb_women_health_profiles
    WHERE user_id = v_user_id
      AND consent_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Trilha não iniciada' USING ERRCODE = '42501';
  END IF;

  v_token := replace(gen_random_uuid()::text, '-', '')
    || replace(gen_random_uuid()::text, '-', '');

  INSERT INTO public.tb_calendar_feeds (user_id, kind, token_hash)
  VALUES (
    v_user_id,
    p_kind,
    encode(sha256(convert_to(v_token, 'UTF8')), 'hex')
  )
  ON CONFLICT (user_id, kind) DO UPDATE
    SET token_hash = EXCLUDED.token_hash,
        last_fetched_at = NULL;

  RETURN v_token;
END;
$$;

REVOKE ALL ON FUNCTION public.connect_calendar_feed(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.connect_calendar_feed(text) TO authenticated;

-- Conta excluída: os links param de funcionar na hora.
CREATE OR REPLACE FUNCTION public.erase_calendar_feeds_on_account_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    DELETE FROM public.tb_calendar_feeds WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.erase_calendar_feeds_on_account_delete() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER erase_calendar_feeds_on_account_delete
  AFTER UPDATE OF deleted_at ON public.tb_users
  FOR EACH ROW EXECUTE FUNCTION public.erase_calendar_feeds_on_account_delete();

-- Saiu da trilha: o link de saúde da mulher deixa de existir junto.
CREATE OR REPLACE FUNCTION public.erase_women_health_feed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  DELETE FROM public.tb_calendar_feeds
  WHERE user_id = OLD.user_id
    AND kind = 'women_health';
  RETURN OLD;
END;
$$;

REVOKE ALL ON FUNCTION public.erase_women_health_feed() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER erase_women_health_feed
  AFTER DELETE ON public.tb_women_health_profiles
  FOR EACH ROW EXECUTE FUNCTION public.erase_women_health_feed();
