-- Registros da Saúde da Mulher: menstruação, tentativas e testes.
-- Só acrescenta: nada existente é apagado ou alterado.
--   - period_start   menstruação começou (value nulo)
--   - period_end     menstruação terminou (value nulo)
--   - no_period      a menstruação não veio no mês (value nulo)
--   - attempt        dia de tentativa (Quero gestar) (value nulo)
--   - ovulation_test value: positive | negative | not_done | own_method
--   - pregnancy_test value: positive | negative | faint_line | not_done
-- Dado sensível de saúde (LGPD): só a dona lê e grava. Nem o painel
-- administrativo nem profissionais têm acesso.

create table if not exists public.tb_women_health_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.tb_users(id) on delete cascade,
  day date not null,
  kind text not null,
  value text,
  note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint tb_women_health_logs_user_day_kind_key unique (user_id, day, kind),
  constraint tb_women_health_logs_kind_check check (
    kind in (
      'period_start', 'period_end', 'no_period',
      'attempt', 'ovulation_test', 'pregnancy_test'
    )
  ),
  constraint tb_women_health_logs_value_check check (
    (kind = 'ovulation_test'
      and value in ('positive', 'negative', 'not_done', 'own_method'))
    or (kind = 'pregnancy_test'
      and value in ('positive', 'negative', 'faint_line', 'not_done'))
    or (kind not in ('ovulation_test', 'pregnancy_test') and value is null)
  ),
  constraint tb_women_health_logs_note_check check (
    note is null or char_length(note) <= 500
  ),
  constraint tb_women_health_logs_day_check check (
    day >= date '2000-01-01' and day <= (now() at time zone 'America/Sao_Paulo')::date + 1
  )
);

comment on table public.tb_women_health_logs is
  'Saúde da Mulher: registro de menstruação, dias de tentativa e testes de ovulação/gravidez. Privado da usuária.';

create index if not exists tb_women_health_logs_user_day_idx
  on public.tb_women_health_logs (user_id, day desc);

drop trigger if exists set_updated_at_trigger_tb_women_health_logs
  on public.tb_women_health_logs;
create trigger set_updated_at_trigger_tb_women_health_logs
  before update on public.tb_women_health_logs
  for each row execute function public.set_updated_at();

alter table public.tb_women_health_logs enable row level security;

drop policy if exists "Own women health logs" on public.tb_women_health_logs;
create policy "Own women health logs"
  on public.tb_women_health_logs
  for all
  to authenticated
  using (user_id = public.get_my_uid())
  with check (user_id = public.get_my_uid());

revoke all on public.tb_women_health_logs from anon;
grant select, insert, update, delete on public.tb_women_health_logs to authenticated;
