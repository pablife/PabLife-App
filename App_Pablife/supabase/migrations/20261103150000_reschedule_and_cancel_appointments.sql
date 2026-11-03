-- Remarcar e cancelar consultas de verdade.
--
-- 1) reschedule_appointment: troca o horário da MESMA consulta (não cria
--    outra, então não gasta consulta do plano). O gatilho existente
--    reschedule_appointment_notifications_on_update refaz os lembretes.
-- 2) Consulta cancelada deixa de ocupar o horário na view de horários
--    livres (antes só uma consulta apagada liberava o horário).
-- 3) Ao cancelar, os lembretes pendentes da consulta são descartados.

-- 1) Remarcar ---------------------------------------------------------------

create or replace function public.reschedule_appointment(
  p_appointment_id uuid,
  p_new_appointment_time_id uuid,
  p_new_slot_date date
)
returns table (rescheduled_id uuid, new_start_at timestamptz)
language plpgsql
security invoker
set search_path to 'public', 'pg_temp'
as $$
declare
  v_appointment record;
  v_slot record;
  v_is_patient boolean;
begin
  -- RLS garante que só o paciente, o profissional da consulta ou um admin
  -- enxergam (e podem alterar) a consulta.
  select a.id, a.professional_id, a.scheduled_by, a.status,
         a.start_of_scheduled_window
    into v_appointment
    from public.tb_appointments a
   where a.id = p_appointment_id
     and a.deleted_at is null
   for update;

  if not found then
    raise exception 'Consulta não encontrada.';
  end if;

  if v_appointment.status::text <> 'scheduled' then
    raise exception 'Só é possível remarcar consultas agendadas.';
  end if;

  -- Checagem explícita de permissão: a RLS de tb_appointments está
  -- desligada no banco, então não dá para contar só com ela.
  v_is_patient := v_appointment.scheduled_by = public.get_my_uid();
  if not (
    v_is_patient
    or public.is_admin()
    or exists (
      select 1 from public.tb_professionals p
       where p.id = v_appointment.professional_id
         and p.deleted_at is null
         and p.user_id = public.get_my_uid()
    )
  ) then
    raise exception 'Consulta não encontrada.';
  end if;

  if v_is_patient
     and v_appointment.start_of_scheduled_window < now() + interval '24 hours' then
    raise exception 'A consulta só pode ser remarcada até 24h antes.';
  end if;

  -- Evita que duas pessoas peguem o mesmo horário ao mesmo tempo.
  perform pg_advisory_xact_lock(
    hashtext(p_new_appointment_time_id::text || p_new_slot_date::text)
  );

  select s.slot_start_at, s.slot_finish_at
    into v_slot
    from public.vw_professional_available_appointment_slots s
   where s.professional_id = v_appointment.professional_id
     and s.appointment_time_id = p_new_appointment_time_id
     and s.slot_date = p_new_slot_date
     and s.is_my_appointment = false
   limit 1;

  if not found then
    raise exception 'Este horário não está mais disponível.';
  end if;

  if v_slot.slot_start_at <= now() then
    raise exception 'Escolha um horário no futuro.';
  end if;

  update public.tb_appointments a
     set appointment_time_id = p_new_appointment_time_id,
         start_of_scheduled_window = v_slot.slot_start_at,
         end_of_scheduled_window = v_slot.slot_finish_at
   where a.id = p_appointment_id;

  return query select p_appointment_id, v_slot.slot_start_at;
end;
$$;

revoke all on function public.reschedule_appointment(uuid, uuid, date) from public, anon;
grant execute on function public.reschedule_appointment(uuid, uuid, date) to authenticated;

-- 2) Consulta cancelada libera o horário --------------------------------------
-- Mesma definição da view, com "ap.status <> 'cancelled'" na busca da consulta
-- que ocupa o horário.

create or replace view public.vw_professional_available_appointment_slots as
 WITH params AS (
         SELECT 180 AS future_day_horizon
        ), my_account AS (
         SELECT get_my_uid() AS user_id
        ), professional_data AS (
         SELECT p.id AS professional_id,
            p.type AS professional_type,
            u.full_name AS professional_full_name,
            u.email::text AS professional_email
           FROM tb_professionals p
             JOIN tb_users u ON p.user_id = u.id
          WHERE p.deleted_at IS NULL AND u.deleted_at IS NULL
        ), explicit_slots AS (
         SELECT t.id AS appointment_time_id,
            t.appointment_recurrence_rule_id,
            pd.professional_id,
            pd.professional_type,
            pd.professional_full_name,
            pd.professional_email,
            t.start_time_at,
            t.finish_time_at,
            t.timezone,
            t.due_at AS slot_date,
            ((t.due_at + t.start_time_at) AT TIME ZONE COALESCE(t.timezone, 'UTC'::character varying)) AS slot_start_at,
            ((t.due_at + t.finish_time_at) AT TIME ZONE COALESCE(t.timezone, 'UTC'::character varying)) AS slot_finish_at
           FROM tb_appointment_times t
             JOIN professional_data pd ON t.professional_id = pd.professional_id
          WHERE t.deleted_at IS NULL AND t.due_at IS NOT NULL AND t.appointment_recurrence_rule_id IS NULL
        ), recurring_sources AS (
         SELECT t.id,
            t.professional_id,
            t.start_time_at,
            t.finish_time_at,
            t.timezone,
            arr.id AS appointment_recurrence_rule_id,
            arr.week_select,
            arr.end_at,
            timezone(arr.timezone::text, arr.start_at)::date AS recurrence_start_date,
            timezone(arr.timezone::text, arr.end_at)::date AS recurrence_end_date
           FROM tb_appointment_times t
             JOIN tb_appointment_recurrence_rules arr ON t.appointment_recurrence_rule_id = arr.id
          WHERE t.deleted_at IS NULL AND arr.deleted_at IS NULL
        ), recurring_slots AS (
         SELECT rs.id AS appointment_time_id,
            rs.appointment_recurrence_rule_id,
            pd.professional_id,
            pd.professional_type,
            pd.professional_full_name,
            pd.professional_email,
            rs.start_time_at,
            rs.finish_time_at,
            rs.timezone,
            future_days.slot_date,
            ((future_days.slot_date + rs.start_time_at) AT TIME ZONE rs.timezone) AS slot_start_at,
            ((future_days.slot_date + rs.finish_time_at) AT TIME ZONE rs.timezone) AS slot_finish_at
           FROM recurring_sources rs
             JOIN professional_data pd ON rs.professional_id = pd.professional_id
             JOIN params ON true
             JOIN LATERAL ( SELECT CURRENT_DATE + g.day_offset AS slot_date
                   FROM generate_series(0, params.future_day_horizon) g(day_offset)
                  WHERE (CURRENT_DATE + g.day_offset) >= rs.recurrence_start_date AND (rs.recurrence_end_date IS NULL OR (CURRENT_DATE + g.day_offset) <= rs.recurrence_end_date) AND EXTRACT(dow FROM CURRENT_DATE + g.day_offset)::integer = rs.week_select) future_days ON true
          WHERE NOT (EXISTS ( SELECT 1
                   FROM tb_appointment_times t2
                  WHERE t2.deleted_at IS NULL AND t2.appointment_recurrence_rule_id IS NULL AND t2.professional_id = rs.professional_id AND t2.due_at = future_days.slot_date AND t2.start_time_at = rs.start_time_at AND t2.finish_time_at = rs.finish_time_at)) AND NOT (EXISTS ( SELECT 1
                   FROM tb_appointment_recurrence_exceptions ex
                  WHERE ex.deleted_at IS NULL AND ex.appointment_time_id = rs.id AND ex.slot_date = future_days.slot_date))
        ), all_slots AS (
         SELECT explicit_slots.appointment_time_id,
            explicit_slots.appointment_recurrence_rule_id,
            explicit_slots.professional_id,
            explicit_slots.professional_type,
            explicit_slots.professional_full_name,
            explicit_slots.professional_email,
            explicit_slots.start_time_at,
            explicit_slots.finish_time_at,
            explicit_slots.timezone,
            explicit_slots.slot_date,
            explicit_slots.slot_start_at,
            explicit_slots.slot_finish_at
           FROM explicit_slots
        UNION ALL
         SELECT recurring_slots.appointment_time_id,
            recurring_slots.appointment_recurrence_rule_id,
            recurring_slots.professional_id,
            recurring_slots.professional_type,
            recurring_slots.professional_full_name,
            recurring_slots.professional_email,
            recurring_slots.start_time_at,
            recurring_slots.finish_time_at,
            recurring_slots.timezone,
            recurring_slots.slot_date,
            recurring_slots.slot_start_at,
            recurring_slots.slot_finish_at
           FROM recurring_slots
        ), slots_with_booking AS (
         SELECT s.appointment_time_id,
            s.appointment_recurrence_rule_id,
            s.professional_id,
            s.professional_type,
            s.professional_full_name,
            s.professional_email,
            s.start_time_at,
            s.finish_time_at,
            s.timezone,
            s.slot_date,
            s.slot_start_at,
            s.slot_finish_at,
            a.id AS appointment_id,
            a.scheduled_by AS appointment_user_id,
            my.user_id AS current_user_id
           FROM all_slots s
             CROSS JOIN my_account my
             LEFT JOIN LATERAL ( SELECT ap.id,
                    ap.scheduled_by
                   FROM tb_appointments ap
                  WHERE ap.appointment_time_id = s.appointment_time_id AND ap.deleted_at IS NULL AND ap.status::text <> 'cancelled'::text AND timezone(s.timezone::text, ap.start_of_scheduled_window)::date = s.slot_date
                  ORDER BY ap.start_of_scheduled_window DESC
                 LIMIT 1) a ON true
          WHERE a.id IS NULL OR my.user_id IS NOT NULL AND a.scheduled_by = my.user_id
        )
 SELECT professional_id,
    appointment_time_id,
    appointment_recurrence_rule_id,
    slot_date,
    EXTRACT(day FROM slot_date)::integer AS slot_day,
    EXTRACT(month FROM slot_date)::integer AS slot_month,
    start_time_at,
    finish_time_at,
    timezone,
    slot_start_at,
    slot_finish_at,
    professional_type,
    professional_full_name,
    professional_email,
    appointment_id IS NOT NULL AS is_my_appointment
   FROM slots_with_booking swb;

-- 3) Cancelada: descarta lembretes pendentes ---------------------------------

create or replace function public.trg_skip_notifications_on_cancel()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  -- Nunca pode impedir o cancelamento: qualquer erro aqui é ignorado.
  begin
    update public.tb_notification_schedule
       set status = 'skipped', error = 'consulta cancelada'
     where appointment_id = new.id and status = 'pending';
  exception when others then
    null;
  end;
  return new;
end;
$$;

drop trigger if exists skip_notifications_on_cancel on public.tb_appointments;
create trigger skip_notifications_on_cancel
  after update of status on public.tb_appointments
  for each row
  when (new.status::text = 'cancelled' and old.status::text is distinct from 'cancelled')
  execute function public.trg_skip_notifications_on_cancel();

-- Função de gatilho não deve ser chamável pela API.
revoke all on function public.trg_skip_notifications_on_cancel() from public, anon, authenticated;
