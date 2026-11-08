-- Cadastro novo (canvas E3–E5 e PC1–PC3):
--   1) registro do conselho do profissional (CRP/CRN e região) e diploma
--      opcional;
--   2) comprovante de estudante (desconto de 10%), guardado em arquivo
--      privado e aprovado pelo admin.
-- Só acrescenta: nada é apagado.

-- 1) Profissional ---------------------------------------------------------

alter table public.tb_professionals
  add column if not exists council_number text,
  add column if not exists council_region text,
  add column if not exists specialization_document_path text;

alter table public.tb_professionals
  drop constraint if exists tb_professionals_council_number_check;
alter table public.tb_professionals
  add constraint tb_professionals_council_number_check
  check (council_number is null or char_length(council_number) <= 30);

alter table public.tb_professionals
  drop constraint if exists tb_professionals_council_region_check;
alter table public.tb_professionals
  add constraint tb_professionals_council_region_check
  check (council_region is null or char_length(council_region) <= 10);

-- O registro só muda pelo admin depois que o perfil foi aprovado (antes, o
-- próprio profissional pode corrigir).
create or replace function public.protect_professional_privileged_columns()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
begin
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    if new.validation_status is distinct from old.validation_status
       or new.user_id is distinct from old.user_id
       or new.deleted_at is distinct from old.deleted_at then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
    if old.validation_status = 'approved'
       and (new.council_number is distinct from old.council_number
            or new.council_region is distinct from old.council_region) then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$function$;

-- 2) Estudante -------------------------------------------------------------

create table if not exists public.tb_student_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.tb_users (id) on delete cascade,
  institution text not null check (char_length(institution) between 2 and 160),
  course text not null check (char_length(course) between 2 and 120),
  document_path text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text check (rejection_reason is null or char_length(rejection_reason) <= 500),
  reviewed_by uuid references public.tb_users (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.tb_student_verifications is
  'Comprovante de estudante para o desconto de 10%. A pessoa vê só os seus; o admin aprova.';

-- No máximo um pedido em análise por pessoa.
create unique index if not exists tb_student_verifications_one_pending
  on public.tb_student_verifications (user_id) where status = 'pending';
create index if not exists tb_student_verifications_status_idx
  on public.tb_student_verifications (status, created_at);

alter table public.tb_student_verifications enable row level security;

drop policy if exists "Own student verifications" on public.tb_student_verifications;
create policy "Own student verifications"
  on public.tb_student_verifications for select to authenticated
  using (user_id = public.get_my_uid() or public.is_admin());

drop policy if exists "Create own student verification" on public.tb_student_verifications;
create policy "Create own student verification"
  on public.tb_student_verifications for insert to authenticated
  with check (user_id = public.get_my_uid() and status = 'pending');

-- A pessoa só mexe no próprio pedido enquanto está em análise (trocar o
-- arquivo); o admin revisa.
drop policy if exists "Update own pending student verification" on public.tb_student_verifications;
create policy "Update own pending student verification"
  on public.tb_student_verifications for update to authenticated
  using ((user_id = public.get_my_uid() and status = 'pending') or public.is_admin())
  with check (user_id = public.get_my_uid() or public.is_admin());

create or replace function public.protect_student_verification()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
begin
  new.updated_at := now();
  if current_user in ('authenticated', 'anon') and not public.is_admin() then
    if new.status is distinct from old.status
       or new.user_id is distinct from old.user_id
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at
       or new.rejection_reason is distinct from old.rejection_reason then
      raise exception 'not_allowed' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists protect_student_verification on public.tb_student_verifications;
create trigger protect_student_verification
  before update on public.tb_student_verifications
  for each row execute function public.protect_student_verification();

-- Status do desconto da pessoa logada: 'approved', 'pending', 'rejected' ou
-- null (nunca pediu).
create or replace function public.my_student_status()
returns text
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $function$
  select status
  from public.tb_student_verifications
  where user_id = public.get_my_uid()
  order by (status = 'approved') desc, created_at desc
  limit 1;
$function$;

revoke all on function public.my_student_status() from public, anon;
grant execute on function public.my_student_status() to authenticated;

-- Admin aprova ou recusa; a pessoa recebe uma notificação no app.
create or replace function public.review_student_verification(
  p_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_user uuid;
begin
  if not public.is_admin() then
    raise exception 'not_allowed' using errcode = '42501';
  end if;

  update public.tb_student_verifications
     set status = case when p_approve then 'approved' else 'rejected' end,
         rejection_reason = case when p_approve then null else nullif(trim(p_reason), '') end,
         reviewed_by = public.get_my_uid(),
         reviewed_at = now()
   where id = p_id and status = 'pending'
  returning user_id into v_user;

  if v_user is null then
    raise exception 'not_found_or_reviewed';
  end if;

  insert into public.tb_notifications (user_id, title, message, metadata)
  values (
    v_user,
    case when p_approve then 'Desconto de estudante aprovado'
         else 'Comprovante de estudante não aprovado' end,
    case when p_approve
         then 'Seu comprovante foi aprovado. Os planos já aparecem com 10% de desconto.'
         else 'Não conseguimos aprovar seu comprovante'
              || coalesce(': ' || nullif(trim(p_reason), ''), '.')
              || ' Você pode enviar outro pelo Perfil.' end,
    jsonb_build_object('type', 'student_verification', 'status',
                       case when p_approve then 'approved' else 'rejected' end)
  );
end;
$function$;

revoke all on function public.review_student_verification(uuid, boolean, text) from public, anon;
grant execute on function public.review_student_verification(uuid, boolean, text) to authenticated;

-- Arquivos dos comprovantes: privados, na pasta da própria pessoa.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('student-proofs', 'student-proofs', false, 10485760,
        array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

drop policy if exists "Student proofs: own upload" on storage.objects;
create policy "Student proofs: own upload"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'student-proofs'
              and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "Student proofs: own or admin read" on storage.objects;
create policy "Student proofs: own or admin read"
  on storage.objects for select to authenticated
  using (bucket_id = 'student-proofs'
         and ((storage.foldername(name))[1] = (auth.uid())::text
              or public.is_admin()));

drop policy if exists "Student proofs: own delete" on storage.objects;
create policy "Student proofs: own delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'student-proofs'
         and (storage.foldername(name))[1] = (auth.uid())::text);
