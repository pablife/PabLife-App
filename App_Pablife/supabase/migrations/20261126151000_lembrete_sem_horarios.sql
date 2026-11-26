-- =====================================================================
-- Item 4: lembrete semanal para o profissional sem horário aberto.
--
-- Toda segunda às 9h (Fortaleza) = 12h UTC, quem é profissional aprovado,
-- com conta ativa, perfil visível e nenhum horário aberto (semanal ou avulso
-- de hoje em diante) recebe
-- um aviso no celular (pelo mesmo sistema dos avisos de consulta).
-- O aviso para sozinho quando a pessoa cria um horário.
-- Não apaga nem altera dados.
-- =====================================================================

begin;

-- Horários abertos: os que repetem toda semana (regra com dia da semana,
-- sem fim no passado) e os avulsos de hoje em diante (sem regra, com data).
create or replace function public.professional_open_slots(p_professional_id uuid)
returns integer language sql stable security definer set search_path = public, pg_temp as $$
  select count(*)::integer
    from public.tb_appointment_times t
    left join public.tb_appointment_recurrence_rules r on r.id = t.appointment_recurrence_rule_id
   where t.professional_id = p_professional_id
     and t.deleted_at is null
     and (
       (r.id is not null and r.deleted_at is null and r.week_select is not null
         and (r.end_at is null or r.end_at >= now()))
       or (t.appointment_recurrence_rule_id is null
         and t.due_at >= (now() at time zone 'America/Fortaleza')::date)
     );
$$;

create or replace function public.enqueue_no_slots_reminders()
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_count integer;
begin
  insert into public.tb_notification_schedule (campaign, scheduled_at, title, message, target_user_id)
  select 'sem-horarios', now(),
         'Seus horários estão fechados',
         'Olá, ' || initcap(lower(split_part(trim(u.full_name), ' ', 1)))
           || '. Você não tem horários abertos, então os pacientes não conseguem marcar com você. '
           || 'Abra a Agenda e toque em "Criar horário".',
         u.id
    from public.tb_professionals p
    join public.tb_users u on u.id = p.user_id
   where p.validation_status = 'approved'
     and p.deleted_at is null
     and coalesce(p.visibility_status, 'high_profile') <> 'low_profile'
     and u.status = 'active'
     and u.deleted_at is null
     and public.professional_open_slots(p.id) = 0
     -- no máximo um por semana
     and not exists (
       select 1 from public.tb_notification_schedule s
        where s.campaign = 'sem-horarios'
          and s.target_user_id = u.id
          and s.created_at > now() - interval '6 days'
     );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.enqueue_no_slots_reminders() from public, anon, authenticated;
revoke all on function public.professional_open_slots(uuid) from public, anon;
grant execute on function public.professional_open_slots(uuid) to authenticated;

select cron.schedule('lembrete-sem-horarios', '0 12 * * 1', $cron$select public.enqueue_no_slots_reminders()$cron$);

commit;

-- Para desfazer:
--   select cron.unschedule('lembrete-sem-horarios');
--   drop function public.enqueue_no_slots_reminders();
--   drop function public.professional_open_slots(uuid);
