-- Saúde da mulher. São dados sensíveis (LGPD): só a própria usuária lê e
-- altera. De propósito, nem o administrador nem o profissional têm acesso.

CREATE TABLE public.tb_women_health_profiles (
  user_id uuid PRIMARY KEY REFERENCES public.tb_users (id) ON DELETE CASCADE,
  trail text CHECK (trail IN ('cycle', 'conceive', 'pregnancy', 'menopause')),
  last_period date,
  cycle_length smallint NOT NULL DEFAULT 28 CHECK (cycle_length BETWEEN 15 AND 60),
  answers jsonb NOT NULL DEFAULT '{}'::jsonb,
  consent_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.tb_women_health_check_ins (
  user_id uuid NOT NULL REFERENCES public.tb_users (id) ON DELETE CASCADE,
  day date NOT NULL,
  mood text NOT NULL CHECK (char_length(mood) <= 40),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, day)
);

CREATE TRIGGER set_updated_at_trigger_tb_women_health_profiles
  BEFORE UPDATE ON public.tb_women_health_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_trigger_tb_women_health_check_ins
  BEFORE UPDATE ON public.tb_women_health_check_ins
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.tb_women_health_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_women_health_check_ins ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.tb_women_health_profiles FROM PUBLIC, anon;
REVOKE ALL ON public.tb_women_health_check_ins FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_women_health_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_women_health_check_ins TO authenticated;

CREATE POLICY "Own women health profile"
  ON public.tb_women_health_profiles
  FOR ALL
  TO authenticated
  USING (user_id = public.get_my_uid())
  WITH CHECK (user_id = public.get_my_uid());

CREATE POLICY "Own women health check-ins"
  ON public.tb_women_health_check_ins
  FOR ALL
  TO authenticated
  USING (user_id = public.get_my_uid())
  WITH CHECK (user_id = public.get_my_uid());
