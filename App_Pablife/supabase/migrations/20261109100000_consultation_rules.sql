-- Regras de consulta da repaginação (etapa 1).
--
-- * Falta (no_show) passa a descontar do saldo.
-- * Paciente remarca até 3 horas antes e cancela até 24 horas antes; com menos
--   de 24 horas ele ainda pode cancelar, mas a consulta não volta ao saldo.
-- * Profissional cancela com menos de 24 horas só com justificativa.
-- * Consulta marcada reserva o saldo, e o banco recusa marcar sem saldo.
-- * Novo status technical_issue e registro de quem cancelou e quando.
--
-- As regras novas valem só para consultas marcadas a partir da data de corte;
-- as anteriores seguem a regra antiga. Nenhum registro é apagado ou alterado.

-- Data de corte. Mudar a data = trocar só esta função.
CREATE OR REPLACE FUNCTION public.consultation_rules_cutoff()
RETURNS timestamptz
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT timestamptz '2026-11-09 00:00:00-03';
$$;

-- --------------------------------------------------------------- colunas

ALTER TABLE public.tb_appointments
  ADD COLUMN IF NOT EXISTS cancelled_by text,
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;

ALTER TABLE public.tb_appointments
  ADD CONSTRAINT tb_appointments_cancelled_by_check
  CHECK (cancelled_by IN ('patient', 'professional'));

ALTER TABLE public.tb_appointments
  DROP CONSTRAINT tb_appointments_status_check;

ALTER TABLE public.tb_appointments
  ADD CONSTRAINT tb_appointments_status_check
  CHECK (status::text IN ('scheduled', 'completed', 'cancelled', 'no_show', 'technical_issue'));

-- ----------------------------------------------------------------- saldo

-- A consulta ocupa uma vaga do saldo? Marcada e concluída sempre ocupam. Com
-- as regras novas, falta e cancelamento do paciente com menos de 24 horas
-- também. Cancelada pelo profissional e problema técnico voltam ao saldo.
CREATE OR REPLACE FUNCTION public.appointment_uses_balance(
  p_status text,
  p_created_at timestamptz,
  p_start timestamptz,
  p_cancelled_by text,
  p_cancelled_at timestamptz
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_status IN ('scheduled', 'completed') THEN true
    WHEN p_created_at < public.consultation_rules_cutoff() THEN false
    WHEN p_status = 'no_show' THEN true
    WHEN p_status = 'cancelled' THEN COALESCE(
      p_cancelled_by = 'patient'
        AND p_cancelled_at > p_start - interval '24 hours',
      false
    )
    ELSE false
  END;
$$;

-- Ciclos pagos (ou de cortesia e cupom) em vigor e quanto já foi usado em
-- cada um. Base de todas as funções de saldo.
CREATE OR REPLACE FUNCTION public.consultation_cycles(p_user_id uuid)
RETURNS TABLE (
  cycle_start timestamptz,
  cycle_end timestamptz,
  consultations integer,
  used_in_cycle integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  WITH cycles AS (
    SELECT
      us.id,
      us.is_courtesy,
      (us.coupon_id IS NOT NULL) AS is_coupon,
      us.renewed_at AS cycle_start,
      us.renewed_at + (sp.duration_months * INTERVAL '30 days') AS cycle_end,
      sp.consultations::integer AS consultations
    FROM public.tb_user_subscriptions us
    JOIN public.tb_subscription_plans sp ON sp.id = us.plan_id
    WHERE us.user_id = p_user_id
      AND us.status IN ('active', 'cancelled')
      AND us.renewed_at IS NOT NULL
      AND (NOT (us.is_courtesy OR us.coupon_id IS NOT NULL) OR us.status = 'active')
      AND us.start_date IS NOT NULL
      AND us.end_date IS NOT NULL
      AND now() BETWEEN us.start_date AND us.end_date
  ),
  paid_cycles AS (
    SELECT c.*
    FROM cycles c
    WHERE c.is_courtesy OR c.is_coupon
       OR EXISTS (
         SELECT 1 FROM public.tb_subscription_transactions tx
         WHERE tx.user_subscription_id = c.id
           AND tx.status = 'approved'
           AND tx.mp_date_approved >= c.cycle_start - INTERVAL '5 minutes'
           AND tx.mp_date_approved <= c.cycle_end
       )
  )
  SELECT
    pc.cycle_start,
    pc.cycle_end,
    pc.consultations,
    (
      SELECT COUNT(*)::integer
      FROM public.tb_appointments ap
      WHERE ap.scheduled_by = p_user_id
        AND ap.deleted_at IS NULL
        AND ap.created_at >= pc.cycle_start
        AND ap.created_at <= pc.cycle_end
        AND public.appointment_uses_balance(
          ap.status::text,
          ap.created_at,
          ap.start_of_scheduled_window,
          ap.cancelled_by,
          ap.cancelled_at
        )
    ) AS used_in_cycle
  FROM paid_cycles pc;
$$;

REVOKE ALL ON FUNCTION public.consultation_cycles(uuid) FROM PUBLIC, anon, authenticated;

-- Consultas que a própria pessoa ainda pode marcar.
CREATE OR REPLACE FUNCTION public.my_consultations_remaining()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT CASE
    WHEN NOT EXISTS (
      SELECT 1 FROM public.tb_user_subscriptions us
      WHERE us.user_id = public.get_my_uid()
        AND us.status IN ('active', 'cancelled')
        AND us.start_date IS NOT NULL
        AND us.end_date IS NOT NULL
        AND now() BETWEEN us.start_date AND us.end_date
    ) THEN 0
    ELSE COALESCE((
      SELECT SUM(GREATEST(c.consultations - c.used_in_cycle, 0))::integer
      FROM public.consultation_cycles(public.get_my_uid()) c
    ), 0)
  END;
$$;

REVOKE ALL ON FUNCTION public.my_consultations_remaining() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_consultations_remaining() TO authenticated;

-- As quatro funções que o app já chama passam a usar a mesma conta.
CREATE OR REPLACE FUNCTION public.get_user_subscription_access_info()
RETURNS TABLE(access_type text, user_id uuid, consultations_total integer, consultations_used integer, consultations_remaining integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id     UUID;
  v_created_at  TIMESTAMPTZ;
  v_access      TEXT := 'free';
  v_valid_count INTEGER := 0;
  v_total       INTEGER := 0;
  v_used        INTEGER := 0;
  v_remaining   INTEGER := 0;
BEGIN
  v_user_id := public.get_my_uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  SELECT u.created_at INTO v_created_at
  FROM public.tb_users u
  WHERE u.id = v_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  SELECT COUNT(*)
  INTO v_valid_count
  FROM public.tb_user_subscriptions us
  WHERE us.user_id = v_user_id
    AND us.status IN ('active', 'cancelled')
    AND us.start_date IS NOT NULL
    AND us.end_date IS NOT NULL
    AND now() BETWEEN us.start_date AND us.end_date;

  IF v_valid_count > 0 THEN
    v_access := 'subscriber';
  ELSIF now() < v_created_at + INTERVAL '7 days' THEN
    v_access := 'trial';
  ELSE
    v_access := 'free';
  END IF;

  SELECT
    COALESCE(SUM(c.consultations), 0),
    COALESCE(SUM(c.used_in_cycle), 0),
    COALESCE(SUM(GREATEST(c.consultations - c.used_in_cycle, 0)), 0)
  INTO v_total, v_used, v_remaining
  FROM public.consultation_cycles(v_user_id) c;

  RETURN QUERY SELECT v_access, v_user_id, v_total, v_used, v_remaining;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_user_subscription_access_info_v2()
RETURNS TABLE(access_type text, user_id uuid, consultations_total integer, consultations_used integer, consultations_remaining integer)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT * FROM public.get_user_subscription_access_info();
$$;

CREATE OR REPLACE FUNCTION public.get_user_consultation_balances()
RETURNS TABLE(consultations_remaining integer, expires_at timestamp with time zone, start_date timestamp with time zone)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := public.get_my_uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  RETURN QUERY
  SELECT
    GREATEST(c.consultations - c.used_in_cycle, 0)::integer,
    c.cycle_end,
    c.cycle_start
  FROM public.consultation_cycles(v_user_id) c
  WHERE GREATEST(c.consultations - c.used_in_cycle, 0) > 0
  ORDER BY c.cycle_start;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_user_consultation_balances_v2()
RETURNS TABLE(consultations_remaining integer, expires_at timestamp with time zone, start_date timestamp with time zone)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT * FROM public.get_user_consultation_balances();
$$;

-- --------------------------------------------------------------- marcar

-- Quem marca pelo app sempre cria uma consulta "agendada", para si, no futuro
-- e com saldo. Profissional aprovado (entrando como usuário) não tem limite.
CREATE OR REPLACE FUNCTION public.guard_appointment_insert()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.scheduled_by IS DISTINCT FROM public.get_my_uid() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  NEW.status := 'scheduled';
  NEW.cancelled_by := NULL;
  NEW.cancelled_at := NULL;
  NEW.cancellation_reason := NULL;
  NEW.started_at := NULL;
  NEW.finished_at := NULL;
  NEW.deleted_at := NULL;

  IF NEW.start_of_scheduled_window <= now() THEN
    RAISE EXCEPTION 'Escolha um horário no futuro.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.tb_professionals p
    WHERE p.user_id = NEW.scheduled_by
      AND p.deleted_at IS NULL
      AND p.validation_status = 'approved'
  ) THEN
    RETURN NEW;
  END IF;

  -- Duas marcações ao mesmo tempo não usam a mesma vaga do saldo.
  PERFORM pg_advisory_xact_lock(hashtext('consultation_balance:' || NEW.scheduled_by::text));

  IF public.my_consultations_remaining() < 1 THEN
    RAISE EXCEPTION 'Você não tem consultas disponíveis no seu plano.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_appointment_insert ON public.tb_appointments;
CREATE TRIGGER guard_appointment_insert
  BEFORE INSERT ON public.tb_appointments
  FOR EACH ROW EXECUTE FUNCTION public.guard_appointment_insert();

-- ------------------------------------------------------------- alterar

-- O que cada um pode mudar numa consulta. Horário só pela remarcação. O
-- paciente só cancela uma consulta agendada; o profissional registra o status.
CREATE OR REPLACE FUNCTION public.guard_appointment_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_uid uuid := public.get_my_uid();
  v_is_professional boolean;
  v_new_rules boolean := OLD.created_at >= public.consultation_rules_cutoff();
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.scheduled_by IS DISTINCT FROM OLD.scheduled_by
     OR NEW.professional_id IS DISTINCT FROM OLD.professional_id
     OR NEW.created_at IS DISTINCT FROM OLD.created_at
     OR NEW.deleted_at IS DISTINCT FROM OLD.deleted_at
     OR NEW.cancelled_by IS DISTINCT FROM OLD.cancelled_by
     OR NEW.cancelled_at IS DISTINCT FROM OLD.cancelled_at THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  IF NEW.appointment_time_id IS DISTINCT FROM OLD.appointment_time_id
     OR NEW.start_of_scheduled_window IS DISTINCT FROM OLD.start_of_scheduled_window
     OR NEW.end_of_scheduled_window IS DISTINCT FROM OLD.end_of_scheduled_window THEN
    RAISE EXCEPTION 'Para mudar o horário, use Remarcar.';
  END IF;

  v_is_professional := EXISTS (
    SELECT 1 FROM public.tb_professionals p
    WHERE p.id = OLD.professional_id
      AND p.deleted_at IS NULL
      AND p.user_id = v_uid
  );

  IF NOT v_is_professional THEN
    IF NEW.started_at IS DISTINCT FROM OLD.started_at
       OR NEW.finished_at IS DISTINCT FROM OLD.finished_at THEN
      RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status THEN
      IF NOT (OLD.status = 'scheduled' AND NEW.status = 'cancelled') THEN
        RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
      END IF;
      IF v_new_rules AND now() >= OLD.start_of_scheduled_window THEN
        RAISE EXCEPTION 'A consulta já começou e não pode mais ser cancelada.';
      END IF;
      NEW.cancelled_by := 'patient';
      NEW.cancelled_at := now();
    ELSIF NEW.cancellation_reason IS DISTINCT FROM OLD.cancellation_reason THEN
      RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
    END IF;

    RETURN NEW;
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NEW.status = 'cancelled' THEN
      IF v_new_rules
         AND now() > OLD.start_of_scheduled_window - interval '24 hours'
         AND COALESCE(btrim(NEW.cancellation_reason), '') = '' THEN
        RAISE EXCEPTION 'Com menos de 24 horas, o cancelamento precisa de justificativa.';
      END IF;
      NEW.cancelled_by := 'professional';
      NEW.cancelled_at := now();
    ELSE
      NEW.cancelled_by := NULL;
      NEW.cancelled_at := NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_appointment_update ON public.tb_appointments;
CREATE TRIGGER guard_appointment_update
  BEFORE UPDATE ON public.tb_appointments
  FOR EACH ROW EXECUTE FUNCTION public.guard_appointment_update();

-- ------------------------------------------------------------- remarcar

-- Paciente remarca até 3 horas antes (regra antiga: 24 horas). Roda com os
-- direitos do banco, depois de conferir quem pede, para poder mudar o horário.
CREATE OR REPLACE FUNCTION public.reschedule_appointment(
  p_appointment_id uuid,
  p_new_appointment_time_id uuid,
  p_new_slot_date date
)
RETURNS TABLE(rescheduled_id uuid, new_start_at timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_appointment record;
  v_slot record;
  v_is_patient boolean;
  v_limit interval;
BEGIN
  SELECT a.id, a.professional_id, a.scheduled_by, a.status,
         a.start_of_scheduled_window, a.created_at
    INTO v_appointment
    FROM public.tb_appointments a
   WHERE a.id = p_appointment_id
     AND a.deleted_at IS NULL
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Consulta não encontrada.';
  END IF;

  IF v_appointment.status::text <> 'scheduled' THEN
    RAISE EXCEPTION 'Só é possível remarcar consultas agendadas.';
  END IF;

  v_is_patient := v_appointment.scheduled_by = public.get_my_uid();
  IF NOT (
    v_is_patient
    OR public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.tb_professionals p
       WHERE p.id = v_appointment.professional_id
         AND p.deleted_at IS NULL
         AND p.user_id = public.get_my_uid()
    )
  ) THEN
    RAISE EXCEPTION 'Consulta não encontrada.';
  END IF;

  v_limit := CASE
    WHEN v_appointment.created_at >= public.consultation_rules_cutoff() THEN interval '3 hours'
    ELSE interval '24 hours'
  END;

  IF v_is_patient AND v_appointment.start_of_scheduled_window < now() + v_limit THEN
    RAISE EXCEPTION 'A consulta só pode ser remarcada até % antes.',
      CASE WHEN v_limit = interval '3 hours' THEN '3 horas' ELSE '24 horas' END;
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtext(p_new_appointment_time_id::text || p_new_slot_date::text)
  );

  SELECT s.slot_start_at, s.slot_finish_at
    INTO v_slot
    FROM public.vw_professional_available_appointment_slots s
   WHERE s.professional_id = v_appointment.professional_id
     AND s.appointment_time_id = p_new_appointment_time_id
     AND s.slot_date = p_new_slot_date
     AND s.is_my_appointment = false
   LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Este horário não está mais disponível.';
  END IF;

  IF v_slot.slot_start_at <= now() THEN
    RAISE EXCEPTION 'Escolha um horário no futuro.';
  END IF;

  UPDATE public.tb_appointments a
     SET appointment_time_id = p_new_appointment_time_id,
         start_of_scheduled_window = v_slot.slot_start_at,
         end_of_scheduled_window = v_slot.slot_finish_at
   WHERE a.id = p_appointment_id;

  RETURN QUERY SELECT p_appointment_id, v_slot.slot_start_at;
END;
$function$;

REVOKE ALL ON FUNCTION public.reschedule_appointment(uuid, uuid, date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reschedule_appointment(uuid, uuid, date) TO authenticated;
