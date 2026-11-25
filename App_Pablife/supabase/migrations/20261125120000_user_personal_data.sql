-- Data de nascimento e gênero.
--
-- Ficam numa tabela separada de tb_users: quem tem consulta com a pessoa lê a
-- linha dela em tb_users, e o cadastro de profissional aprovado é lido por
-- qualquer conta logada. Aqui só a própria pessoa e o administrador leem.
--
-- O app é para maiores de 18 anos; o gênero é opcional.

CREATE TABLE IF NOT EXISTS public.tb_user_personal_data (
  user_id uuid PRIMARY KEY REFERENCES public.tb_users (id) ON DELETE CASCADE,
  birth_date date,
  gender text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_personal_data_gender_check CHECK (
    gender IN (
      'feminino', 'masculino', 'nao_binario', 'outro', 'prefiro_nao_informar'
    )
  ),
  CONSTRAINT user_personal_data_birth_date_min_check CHECK (
    birth_date >= DATE '1900-01-01'
  ),
  CONSTRAINT user_personal_data_adult_check CHECK (
    birth_date <= (CURRENT_DATE - INTERVAL '18 years')::date
  )
);

DROP TRIGGER IF EXISTS set_updated_at_trigger_tb_user_personal_data ON public.tb_user_personal_data;
CREATE TRIGGER set_updated_at_trigger_tb_user_personal_data
  BEFORE UPDATE ON public.tb_user_personal_data
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.tb_user_personal_data ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.tb_user_personal_data FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.tb_user_personal_data TO authenticated;

DROP POLICY IF EXISTS "Own personal data" ON public.tb_user_personal_data;
CREATE POLICY "Own personal data"
  ON public.tb_user_personal_data
  FOR ALL
  TO authenticated
  USING (user_id = public.get_my_uid())
  WITH CHECK (user_id = public.get_my_uid());

DROP POLICY IF EXISTS "Admin views personal data" ON public.tb_user_personal_data;
CREATE POLICY "Admin views personal data"
  ON public.tb_user_personal_data
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- Conta excluída: os dados somem junto.
CREATE OR REPLACE FUNCTION public.erase_personal_data_on_account_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    DELETE FROM public.tb_user_personal_data WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.erase_personal_data_on_account_delete() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS erase_personal_data_on_account_delete ON public.tb_users;
CREATE TRIGGER erase_personal_data_on_account_delete
  AFTER UPDATE OF deleted_at ON public.tb_users
  FOR EACH ROW EXECUTE FUNCTION public.erase_personal_data_on_account_delete();
