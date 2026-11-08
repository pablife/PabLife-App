-- Telas de consulta (canvas Q1–Q6) e Editar perfil (S1).
-- Só acrescenta: nada é apagado.

-- 1) Link da sala de atendimento do profissional --------------------------
-- Fica numa tabela à parte: os dados do profissional aprovado são lidos por
-- qualquer pessoa logada, e o link não pode vazar. O paciente só recebe o
-- link pela função abaixo, da própria consulta e perto do horário.

create table if not exists public.tb_professional_meeting_links (
  professional_id uuid primary key references public.tb_professionals (id) on delete cascade,
  meeting_url text not null
    check (meeting_url ~ '^https://' and char_length(meeting_url) <= 300),
  updated_at timestamptz not null default now()
);

comment on table public.tb_professional_meeting_links is
  'Link da sala de vídeo do profissional. Paciente recebe só via get_appointment_meeting_url.';

alter table public.tb_professional_meeting_links enable row level security;

drop policy if exists "Own meeting link" on public.tb_professional_meeting_links;
create policy "Own meeting link"
  on public.tb_professional_meeting_links for all to authenticated
  using (
    public.is_admin()
    or exists (select 1 from public.tb_professionals p
               where p.id = professional_id and p.user_id = public.get_my_uid()
                 and p.deleted_at is null)
  )
  with check (
    public.is_admin()
    or exists (select 1 from public.tb_professionals p
               where p.id = professional_id and p.user_id = public.get_my_uid()
                 and p.deleted_at is null)
  );

drop trigger if exists set_updated_at_trigger_tb_professional_meeting_links on public.tb_professional_meeting_links;
create trigger set_updated_at_trigger_tb_professional_meeting_links
  before update on public.tb_professional_meeting_links
  for each row execute function public.set_updated_at();

-- A sala abre 15 minutos antes e fecha no fim da consulta.
create or replace function public.get_appointment_meeting_url(p_appointment_id uuid)
returns text
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $function$
  select l.meeting_url
  from public.tb_appointments a
  join public.tb_professionals p on p.id = a.professional_id
  join public.tb_professional_meeting_links l on l.professional_id = a.professional_id
  where a.id = p_appointment_id
    and a.deleted_at is null
    and a.status = 'scheduled'
    and (a.scheduled_by = public.get_my_uid() or p.user_id = public.get_my_uid())
    and now() between a.start_of_scheduled_window - interval '15 minutes'
                  and a.end_of_scheduled_window;
$function$;

revoke all on function public.get_appointment_meeting_url(uuid) from public, anon;
grant execute on function public.get_appointment_meeting_url(uuid) to authenticated;

-- 2) Avaliação da consulta (Q5) -------------------------------------------
-- Só a própria pessoa e a equipe (admin) leem; o profissional não vê.

create table if not exists public.tb_appointment_ratings (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.tb_appointments (id) on delete cascade,
  user_id uuid not null references public.tb_users (id) on delete cascade,
  professional_id uuid not null references public.tb_professionals (id) on delete cascade,
  score smallint not null check (score between 1 and 5),
  highlights text[] not null default '{}' check (cardinality(highlights) <= 10),
  comment text check (comment is null or char_length(comment) <= 1000),
  created_at timestamptz not null default now()
);

create index if not exists tb_appointment_ratings_professional_idx
  on public.tb_appointment_ratings (professional_id, created_at);

alter table public.tb_appointment_ratings enable row level security;

drop policy if exists "Own or admin read ratings" on public.tb_appointment_ratings;
create policy "Own or admin read ratings"
  on public.tb_appointment_ratings for select to authenticated
  using (user_id = public.get_my_uid() or public.is_admin());

-- Só avalia a própria consulta, depois do horário de início.
drop policy if exists "Rate own appointment" on public.tb_appointment_ratings;
create policy "Rate own appointment"
  on public.tb_appointment_ratings for insert to authenticated
  with check (
    user_id = public.get_my_uid()
    and exists (
      select 1 from public.tb_appointments a
      where a.id = appointment_id
        and a.scheduled_by = public.get_my_uid()
        and a.professional_id = tb_appointment_ratings.professional_id
        and a.deleted_at is null
        and a.status <> 'cancelled'
        and a.start_of_scheduled_window <= now()
    )
  );

-- 3) Editar perfil (S1) ---------------------------------------------------

alter table public.tb_users
  add column if not exists preferred_name text
    check (preferred_name is null or char_length(preferred_name) <= 40);

alter table public.tb_user_preferences
  add column if not exists push_notifications boolean not null default true;

-- 4) LGPD: ao excluir a conta, apagar avaliações e comprovantes ------------

create or replace function public.erase_student_and_ratings_on_account_delete()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    delete from public.tb_appointment_ratings where user_id = new.id;
    delete from public.tb_student_verifications where user_id = new.id;
  end if;
  return new;
end;
$function$;

drop trigger if exists erase_student_and_ratings_on_account_delete on public.tb_users;
create trigger erase_student_and_ratings_on_account_delete
  after update of deleted_at on public.tb_users
  for each row execute function public.erase_student_and_ratings_on_account_delete();
