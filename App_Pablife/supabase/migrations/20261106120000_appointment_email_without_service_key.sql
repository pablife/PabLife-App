-- O e-mail de consulta agendada era disparado por um gatilho com a chave
-- service_role escrita na própria definição, e a função send-appointment-email
-- aceitava chamadas de qualquer pessoa. Agora o gatilho usa um segredo próprio,
-- guardado no cofre do banco: ele só vale para esta função e nunca sai do banco.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.secrets WHERE name = 'appointment_email_secret'
  ) THEN
    PERFORM vault.create_secret(
      encode(
        sha256(convert_to(gen_random_uuid()::text || gen_random_uuid()::text, 'UTF8')),
        'hex'
      ),
      'appointment_email_secret',
      'Autoriza o banco a chamar a função send-appointment-email'
    );
  END IF;
END;
$$;

-- A função confere aqui se o segredo recebido é o certo, sem nunca lê-lo.
CREATE OR REPLACE FUNCTION public.appointment_email_secret_valid(p_secret text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM vault.decrypted_secrets
    WHERE name = 'appointment_email_secret'
      AND decrypted_secret = p_secret
  );
$$;

REVOKE ALL ON FUNCTION public.appointment_email_secret_valid(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.appointment_email_secret_valid(text) TO service_role;

-- Nunca impede o agendamento: qualquer falha aqui só fica sem e-mail.
CREATE OR REPLACE FUNCTION public.notify_appointment_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets
  WHERE name = 'appointment_email_secret'
  LIMIT 1;

  IF v_secret IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := 'https://codfvqwqsypxqewlcrcj.supabase.co/functions/v1/send-appointment-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-email-secret', v_secret
    ),
    body := jsonb_build_object(
      'record', jsonb_build_object(
        'scheduled_by', NEW.scheduled_by,
        'professional_id', NEW.professional_id,
        'appointment_time_id', NEW.appointment_time_id,
        'start_of_scheduled_window', NEW.start_of_scheduled_window
      )
    ),
    timeout_milliseconds := 5000
  );
  RETURN NEW;
EXCEPTION WHEN others THEN
  RAISE WARNING 'notify_appointment_email falhou: %', SQLERRM;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_appointment_email() FROM PUBLIC, anon, authenticated;

DROP TRIGGER on_appointment_created ON public.tb_appointments;

CREATE TRIGGER on_appointment_created
  AFTER INSERT ON public.tb_appointments
  FOR EACH ROW EXECUTE FUNCTION public.notify_appointment_email();
