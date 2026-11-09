-- Etapa 4: o profissional registra como foi a consulta (canvas PD e PS).
--
-- Cinco resultados:
--   completed             Consulta concluída
--   no_show               Paciente não compareceu (desconta do saldo)
--   cancelled_patient     Cancelada pelo paciente (avisou por fora do app)
--   cancelled_professional Cancelada por mim (volta para o saldo)
--   technical_issue       Problema técnico (volta para o saldo)
--
-- O saldo segue a regra que já existe (appointment_uses_balance): falta e
-- cancelamento do paciente com menos de 24 h contam; os demais devolvem.
-- Só o profissional da consulta registra. Concluída, falta e problema
-- técnico só depois do horário de início. Dá para corrigir um registro
-- feito nas últimas 24 horas.

create or replace function public.register_appointment_outcome(
  p_appointment_id uuid,
  p_outcome text,
  p_reason text default null
)
returns text
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_uid uuid := public.get_my_uid();
  v_appt public.tb_appointments%rowtype;
  v_prof_name text;
  v_when text;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if p_outcome not in (
    'completed', 'no_show', 'cancelled_patient',
    'cancelled_professional', 'technical_issue'
  ) then
    raise exception 'Resultado inválido.';
  end if;

  select a.* into v_appt
    from public.tb_appointments a
    join public.tb_professionals p on p.id = a.professional_id
   where a.id = p_appointment_id
     and a.deleted_at is null
     and p.deleted_at is null
     and p.user_id = v_uid
   for update of a;

  if not found then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  -- Já registrada há mais de 24 h: não muda mais (o histórico fica fiel).
  if v_appt.status <> 'scheduled'
     and coalesce(v_appt.cancelled_at, v_appt.finished_at, v_appt.updated_at)
         < now() - interval '24 hours' then
    raise exception 'Este registro já foi fechado e não pode mais ser alterado.';
  end if;

  if p_outcome in ('completed', 'no_show', 'technical_issue')
     and now() < v_appt.start_of_scheduled_window then
    raise exception 'Só dá para registrar isso depois do horário da consulta.';
  end if;

  if p_outcome = 'cancelled_professional'
     and now() > v_appt.start_of_scheduled_window - interval '24 hours'
     and v_reason is null then
    raise exception 'Com menos de 24 horas, o cancelamento precisa de justificativa.';
  end if;

  update public.tb_appointments
     set status = case p_outcome
           when 'cancelled_patient' then 'cancelled'
           when 'cancelled_professional' then 'cancelled'
           else p_outcome
         end,
         cancelled_by = case p_outcome
           when 'cancelled_patient' then 'patient'
           when 'cancelled_professional' then 'professional'
           else null
         end,
         cancelled_at = case
           when p_outcome like 'cancelled_%' then now()
           else null
         end,
         cancellation_reason = case
           when p_outcome like 'cancelled_%' or p_outcome = 'technical_issue'
             then v_reason
           else null
         end,
         finished_at = case
           when p_outcome = 'completed' then coalesce(v_appt.finished_at, now())
           else v_appt.finished_at
         end
   where id = v_appt.id;

  -- Avisa o paciente quando a consulta volta para o saldo por causa do
  -- profissional (o app mostra em Notificações).
  if p_outcome in ('cancelled_professional', 'technical_issue') then
    select coalesce(u.preferred_name, u.full_name) into v_prof_name
      from public.tb_professionals p
      join public.tb_users u on u.id = p.user_id
     where p.id = v_appt.professional_id;
    v_when := to_char(
      v_appt.start_of_scheduled_window at time zone 'America/Sao_Paulo',
      'DD/MM "às" HH24:MI'
    );
    insert into public.tb_notifications (user_id, title, message, metadata)
    values (
      v_appt.scheduled_by,
      case p_outcome
        when 'technical_issue' then 'Consulta com problema técnico'
        else 'Consulta cancelada pelo profissional'
      end,
      'Sua consulta de ' || v_when || ' com ' || coalesce(v_prof_name, 'o profissional')
        || ' não aconteceu e voltou para o seu saldo. Escolha um novo horário.',
      jsonb_build_object(
        'type', 'appointment_outcome',
        'appointment_id', v_appt.id,
        'outcome', p_outcome
      )
    );
  end if;

  return p_outcome;
end;
$$;

revoke all on function public.register_appointment_outcome(uuid, text, text) from public, anon;
grant execute on function public.register_appointment_outcome(uuid, text, text) to authenticated;

comment on function public.register_appointment_outcome(uuid, text, text) is
  'O profissional registra como foi a consulta: completed, no_show, cancelled_patient, cancelled_professional ou technical_issue.';
