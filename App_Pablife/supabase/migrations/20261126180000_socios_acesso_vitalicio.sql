-- =====================================================================
-- Sócios: acesso vitalício com consultas sem limite.
--
-- Carlos Yuri Sousa, Rafael Paulino Bulhões e Kierlin Mota Amarilo são os
-- sócios da Pablife. Não pagam plano; a empresa paga o repasse aos
-- psicólogos. Recebem a mesma exceção do profissional aprovado: podem
-- marcar consulta sem plano e sem limite.
--
--  * tb_lifetime_members: a lista (só a administração lê e grava).
--  * am_i_lifetime_member(): o app pergunta se quem está logado é sócio.
--  * guard_appointment_insert: libera a marcação para quem está na lista
--    (mesmo texto da função atual, com uma condição a mais).
-- Não altera nem apaga dados existentes.
-- =====================================================================

begin;

create table public.tb_lifetime_members (
  user_id    uuid primary key references public.tb_users(id) on delete cascade,
  reason     text not null,
  granted_at timestamptz not null default now()
);

comment on table public.tb_lifetime_members is
  'Acesso vitalício sem plano e com consultas sem limite (sócios). A Pablife paga o repasse aos psicólogos.';

alter table public.tb_lifetime_members enable row level security;
revoke all on public.tb_lifetime_members from public, anon, authenticated;

create policy "Admin manage lifetime members" on public.tb_lifetime_members
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.tb_lifetime_members to authenticated;

insert into public.tb_lifetime_members (user_id, reason) values
  ('0cd14cef-1a4c-4a6b-8906-32686b8a13aa', 'Sócio: Carlos Yuri Sousa'),
  ('66159a68-1cd5-4c20-9bf8-661ebba01287', 'Sócio: Rafael Paulino Bulhões'),
  ('f603714b-97bb-4b77-ad52-da2a3d478137', 'Sócio: Kierlin Mota Amarilo');

create or replace function public.am_i_lifetime_member()
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (
    select 1 from public.tb_lifetime_members m
     where m.user_id = public.get_my_uid()
  );
$$;

revoke all on function public.am_i_lifetime_member() from public, anon;
grant execute on function public.am_i_lifetime_member() to authenticated;

CREATE OR REPLACE FUNCTION public.guard_appointment_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF current_user NOT IN ('authenticated', 'anon') OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.scheduled_by IS DISTINCT FROM public.get_my_uid() THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  NEW.status := 'scheduled';
  NEW.cancelled_by := NULL;
  NEW.cancelled_at := NULL;
  NEW.cancellation_reason := NULL;
  NEW.started_at := NULL;
  NEW.finished_at := NULL;
  NEW.deleted_at := NULL;

  IF NEW.start_of_scheduled_window <= now() THEN
    RAISE EXCEPTION 'Escolha um horário no futuro.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.tb_professionals p
    WHERE p.user_id = NEW.scheduled_by
      AND p.deleted_at IS NULL
      AND p.validation_status = 'approved'
  ) THEN
    RETURN NEW;
  END IF;

  -- Sócios: acesso vitalício, sem plano e sem limite.
  IF public.am_i_lifetime_member() THEN
    RETURN NEW;
  END IF;

  -- Duas marcações ao mesmo tempo não usam a mesma vaga do saldo.
  PERFORM pg_advisory_xact_lock(hashtext('consultation_balance:' || NEW.scheduled_by::text));

  IF public.my_consultations_remaining() < 1 THEN
    RAISE EXCEPTION 'Você não tem consultas disponíveis no seu plano.';
  END IF;

  RETURN NEW;
END;
$function$;

commit;

-- Para desfazer:
--   (refazer guard_appointment_insert sem o bloco "Sócios")
--   drop function public.am_i_lifetime_member();
--   drop table public.tb_lifetime_members;
