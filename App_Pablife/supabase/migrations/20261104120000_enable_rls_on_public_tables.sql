-- Liga a RLS nas 20 tabelas que estavam sem ela. As regras dessas tabelas já
-- existiam; aqui entram só as que faltavam para o app continuar funcionando:
--  * profissional precisa ver nome, foto e telefone dos seus pacientes;
--  * paciente precisa ver o profissional das suas consultas, mesmo que ele
--    não esteja mais aprovado ou ativo;
--  * os dois precisam ver o horário de uma consulta, mesmo apagado da agenda;
--  * a usuária precisa conseguir apagar as próprias notificações.

-- Funções SECURITY DEFINER: evitam a recursão entre as regras de tb_users,
-- tb_professionals e tb_appointments, que consultam umas às outras.
CREATE OR REPLACE FUNCTION public.has_appointment_with_user(other_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tb_appointments a
    JOIN public.tb_professionals p ON p.id = a.professional_id
    WHERE a.deleted_at IS NULL
      AND (
        (a.scheduled_by = public.get_my_uid() AND p.user_id = other_user_id)
        OR (p.user_id = public.get_my_uid() AND a.scheduled_by = other_user_id)
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.has_appointment_with_professional(target_professional_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tb_appointments a
    WHERE a.deleted_at IS NULL
      AND a.professional_id = target_professional_id
      AND a.scheduled_by = public.get_my_uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.has_appointment_at_time(target_time_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tb_appointments a
    LEFT JOIN public.tb_professionals p ON p.id = a.professional_id
    WHERE a.deleted_at IS NULL
      AND a.appointment_time_id = target_time_id
      AND (a.scheduled_by = public.get_my_uid() OR p.user_id = public.get_my_uid())
  );
$$;

REVOKE ALL ON FUNCTION public.has_appointment_with_user(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_appointment_with_professional(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.has_appointment_at_time(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_appointment_with_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_appointment_with_professional(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_appointment_at_time(uuid) TO authenticated;

-- Consulta cujo horário foi retirado da agenda continua precisando dele.
CREATE POLICY "View appointment times of my appointments"
  ON public.tb_appointment_times
  FOR SELECT
  TO authenticated
  USING (public.has_appointment_at_time(id));

CREATE POLICY "View users of my appointments"
  ON public.tb_users
  FOR SELECT
  TO authenticated
  USING (public.has_appointment_with_user(id));

CREATE POLICY "View professionals of my appointments"
  ON public.tb_professionals
  FOR SELECT
  TO authenticated
  USING (public.has_appointment_with_professional(id));

-- A regra antiga exigia deleted_at nulo também depois da alteração, o que
-- impedia a usuária de apagar a própria notificação.
DROP POLICY "Update notifications data" ON public.tb_notifications;
CREATE POLICY "Update notifications data"
  ON public.tb_notifications
  FOR UPDATE
  USING (public.is_admin() OR (deleted_at IS NULL AND user_id = public.get_my_uid()))
  WITH CHECK (public.is_admin() OR user_id = public.get_my_uid());

ALTER TABLE public.tb_activity_recurrence_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_appointment_recurrence_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_appointment_recurrence_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_appointment_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_appointment_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_favorite_mentorships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_mentoring_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_mentoring_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_mentorships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_mercadopago_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_module_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_motivational_phrases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_patient_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_rules_professional_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_users ENABLE ROW LEVEL SECURITY;
