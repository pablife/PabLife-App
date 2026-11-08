-- Versículo do dia: o admin cadastra os versículos (na tradução que
-- escolher) e o app mostra um por dia, igual para todos. A pessoa pode
-- tirar o card do Dashboard em Perfil > Ferramentas.
-- Só acrescenta: nada é apagado.

create table if not exists public.tb_daily_verses (
  id uuid primary key default gen_random_uuid(),
  reference text not null check (char_length(reference) between 3 and 80),
  text text not null check (char_length(text) between 5 and 600),
  translation text check (translation is null or char_length(translation) <= 40),
  active boolean not null default true,
  created_by uuid references public.tb_users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.tb_daily_verses is
  'Versículos do card "Versículo do dia". Só o admin cadastra e edita.';

alter table public.tb_daily_verses enable row level security;

drop policy if exists "Read active verses" on public.tb_daily_verses;
create policy "Read active verses"
  on public.tb_daily_verses for select to authenticated
  using (active or public.is_admin());

drop policy if exists "Admin manages verses" on public.tb_daily_verses;
create policy "Admin manages verses"
  on public.tb_daily_verses for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop trigger if exists set_updated_at_trigger_tb_daily_verses on public.tb_daily_verses;
create trigger set_updated_at_trigger_tb_daily_verses
  before update on public.tb_daily_verses
  for each row execute function public.set_updated_at();

-- O versículo de hoje (horário de Brasília): roda a lista em ordem, um por
-- dia, e recomeça quando acaba.
create or replace function public.verse_of_the_day()
returns table (reference text, text text, translation text)
language sql
stable
security invoker
set search_path to 'public', 'pg_temp'
as $function$
  with verses as (
    select v.reference, v.text, v.translation,
           row_number() over (order by v.created_at, v.id) - 1 as pos,
           count(*) over () as total
    from public.tb_daily_verses v
    where v.active
  )
  select reference, text, translation
  from verses
  where pos = ((now() at time zone 'America/Sao_Paulo')::date - date '2026-01-01') % total;
$function$;

revoke all on function public.verse_of_the_day() from public, anon;
grant execute on function public.verse_of_the_day() to authenticated;

-- Preferência da pessoa (tabela que só ela lê e grava).
alter table public.tb_user_preferences
  add column if not exists show_daily_verse boolean not null default true;
