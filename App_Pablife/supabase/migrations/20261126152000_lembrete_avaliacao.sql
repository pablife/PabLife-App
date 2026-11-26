-- =====================================================================
-- Item 5: um lembrete para avaliar a sessão, no dia seguinte às 10h.
--
-- Quando a consulta passa para "completed", agenda UM aviso para o paciente
-- no dia seguinte às 10h (fuso do horário da consulta; padrão Fortaleza).
-- Se ele avaliar antes, ou se a profissional corrigir o resultado, o aviso
-- é pulado. Só um lembrete por sessão (índice único).
--
-- O aviso usa a coluna nova rating_appointment_id, e não appointment_id:
-- o envio pula avisos de consultas que não estão mais "agendadas".
-- Não apaga nem altera dados; sessões já concluídas não recebem lembrete.
-- =====================================================================

begin;

alter table public.tb_notification_schedule
  add column if not exists rating_appointment_id uuid references public.tb_appointments(id) on delete cascade;

comment on column public.tb_notification_schedule.rating_appointment_id is
  'Sessão concluída cujo lembrete de avaliação é este aviso (um por sessão)';

create unique index if not exists tb_notification_schedule_rating_uidx
  on public.tb_notification_schedule (rating_appointment_id)
  where rating_appointment_id is not null;

create or replace function public.trg_rating_reminder()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tz text;
  v_day date;
  v_prof text;
begin
  -- Nunca pode impedir a profissional de registrar o resultado.
  begin
    if new.status = 'completed' and old.status is distinct from 'completed' then
      if exists (select 1 from public.tb_appointment_ratings where appointment_id = new.id) then
        return new;
      end if;
      select coalesce(nullif(t.timezone, ''), 'America/Fortaleza') into v_tz
        from public.tb_appointment_times t where t.id = new.appointment_time_id;
      v_tz := coalesce(v_tz, 'America/Fortaleza');
      v_day := (coalesce(new.finished_at, now()) at time zone v_tz)::date + 1;

      select initcap(lower(trim(u.full_name))) into v_prof
        from public.tb_professionals p join public.tb_users u on u.id = p.user_id
       where p.id = new.professional_id;

      insert into public.tb_notification_schedule
        (campaign, scheduled_at, title, message, target_user_id, rating_appointment_id)
      values (
        'avaliacao-sessao',
        (v_day + time '10:00') at time zone v_tz,
        'Como foi sua consulta? ⭐',
        'Conte como foi sua consulta com ' || coalesce(v_prof, 'a profissional')
          || '. Leva menos de 1 minuto: abra o app para avaliar.',
        new.scheduled_by,
        new.id
      )
      -- Só um por sessão. Se a profissional corrigiu e voltou para "concluída",
      -- o lembrete pulado por essa correção volta a valer.
      on conflict (rating_appointment_id) where rating_appointment_id is not null do update
        set status = 'pending', error = null, scheduled_at = excluded.scheduled_at
        where public.tb_notification_schedule.status = 'skipped'
          and public.tb_notification_schedule.error = 'resultado da consulta alterado';
    elsif old.status = 'completed' and new.status is distinct from 'completed' then
      update public.tb_notification_schedule
         set status = 'skipped', error = 'resultado da consulta alterado'
       where rating_appointment_id = new.id and status = 'pending';
    end if;
  exception when others then
    null;
  end;
  return new;
end;
$$;

drop trigger if exists rating_reminder_on_status on public.tb_appointments;
create trigger rating_reminder_on_status
  after update of status on public.tb_appointments
  for each row
  when (old.status is distinct from new.status)
  execute function public.trg_rating_reminder();

-- Avaliou: o lembrete pendente não é mais enviado.
create or replace function public.trg_skip_rating_reminder()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  begin
    update public.tb_notification_schedule
       set status = 'skipped', error = 'sessão já avaliada'
     where rating_appointment_id = new.appointment_id and status = 'pending';
  exception when others then
    null;
  end;
  return new;
end;
$$;

drop trigger if exists skip_rating_reminder_on_rating on public.tb_appointment_ratings;
create trigger skip_rating_reminder_on_rating
  after insert on public.tb_appointment_ratings
  for each row execute function public.trg_skip_rating_reminder();

revoke all on function public.trg_rating_reminder() from public, anon, authenticated;
revoke all on function public.trg_skip_rating_reminder() from public, anon, authenticated;

commit;

-- Para desfazer:
--   drop trigger rating_reminder_on_status on public.tb_appointments;
--   drop trigger skip_rating_reminder_on_rating on public.tb_appointment_ratings;
--   drop function public.trg_rating_reminder();
--   drop function public.trg_skip_rating_reminder();
--   (a coluna rating_appointment_id pode ficar; vazia não atrapalha)
