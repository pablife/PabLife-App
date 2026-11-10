-- "Meu diário" da Saúde da Mulher: uma anotação por dia, editável.
-- Só acrescenta: nada existente é apagado ou alterado.
--   - A dona lê e grava as próprias anotações.
--   - A profissional só LÊ as anotações que a paciente marcou como
--     compartilhadas, e só se tiver vínculo com ela: consulta marcada
--     (tb_appointments.scheduled_by) ou ficha em tb_patients, o mesmo
--     critério das políticas que já existem nessas tabelas.
--   - As notas antigas de tb_women_health_check_ins.note são copiadas para
--     day_text. A coluna note continua lá.

create table if not exists public.tb_women_health_diary_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.tb_users(id) on delete cascade,
  day date not null,
  habits text[] not null default '{}',
  day_text text,
  felt_good text,
  to_remember text,
  -- Dia do ciclo quando a anotação foi feita (a profissional não lê o perfil
  -- de saúde da paciente, só o que está na anotação compartilhada).
  cycle_day smallint check (cycle_day is null or cycle_day between 1 and 60),
  shared_with_professional boolean not null default false,
  shared_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint tb_women_health_diary_entries_user_day_key unique (user_id, day),
  constraint tb_women_health_diary_entries_habits_check check (
    habits <@ array[
      'agua', 'exercicio', 'alimentacao', 'sono',
      'trabalho', 'estudo', 'tempo_pra_mim', 'encontro'
    ]::text[]
  ),
  constraint tb_women_health_diary_entries_text_check check (
    (day_text is null or char_length(day_text) <= 4000)
    and (felt_good is null or char_length(felt_good) <= 4000)
    and (to_remember is null or char_length(to_remember) <= 4000)
  )
);

comment on table public.tb_women_health_diary_entries is
  'Meu diário (Saúde da Mulher). Privado; a profissional vinculada só lê o que a paciente compartilhou.';

create index if not exists tb_women_health_diary_entries_shared_idx
  on public.tb_women_health_diary_entries (user_id, day)
  where shared_with_professional;

drop trigger if exists set_updated_at_trigger_tb_women_health_diary_entries
  on public.tb_women_health_diary_entries;
create trigger set_updated_at_trigger_tb_women_health_diary_entries
  before update on public.tb_women_health_diary_entries
  for each row execute function public.set_updated_at();

-- Marca a hora do compartilhamento (e limpa quando ela desliga).
create or replace function public.women_diary_set_shared_at()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $$
begin
  if new.shared_with_professional then
    if tg_op = 'INSERT' or not coalesce(old.shared_with_professional, false) then
      new.shared_at := now();
    end if;
  else
    new.shared_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists women_diary_set_shared_at_trigger
  on public.tb_women_health_diary_entries;
create trigger women_diary_set_shared_at_trigger
  before insert or update on public.tb_women_health_diary_entries
  for each row execute function public.women_diary_set_shared_at();

-- A profissional logada tem vínculo com a usuária [target_user_id]?
create or replace function public.is_my_patient(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  select exists (
    select 1
    from public.tb_professionals p
    where p.user_id = public.get_my_uid()
      and p.deleted_at is null
      and (
        exists (
          select 1 from public.tb_appointments a
          where a.professional_id = p.id
            and a.scheduled_by = target_user_id
            and a.deleted_at is null
        )
        or exists (
          select 1 from public.tb_patients pt
          where pt.professional_id = p.id
            and pt.user_id = target_user_id
            and pt.deleted_at is null
        )
      )
  );
$$;

revoke all on function public.is_my_patient(uuid) from public, anon;
grant execute on function public.is_my_patient(uuid) to authenticated;

alter table public.tb_women_health_diary_entries enable row level security;

drop policy if exists "Own women health diary" on public.tb_women_health_diary_entries;
create policy "Own women health diary"
  on public.tb_women_health_diary_entries
  for all
  using (user_id = public.get_my_uid())
  with check (user_id = public.get_my_uid());

drop policy if exists "Professional reads shared diary"
  on public.tb_women_health_diary_entries;
create policy "Professional reads shared diary"
  on public.tb_women_health_diary_entries
  for select
  using (shared_with_professional and public.is_my_patient(user_id));

grant select, insert, update, delete
  on public.tb_women_health_diary_entries to authenticated;

-- Cópia das notas antigas do "Como estou hoje".
insert into public.tb_women_health_diary_entries (user_id, day, day_text)
select c.user_id, c.day, trim(c.note)
from public.tb_women_health_check_ins c
where coalesce(trim(c.note), '') <> ''
on conflict (user_id, day) do nothing;
