-- =====================================================================
-- Pablife · Vínculo institucional: proteções (NÃO APLICADO)
-- Roda DEPOIS de 20261126120000_vinculo_institucional.sql, sem alterá-la.
--
-- 1. Excluir conta apaga o vínculo (organização, cargo e sugestão).
--    A exclusão só preenche tb_users.deleted_at, então o "on delete cascade"
--    da tabela nunca dispara. Mesma ideia de erase_women_health_on_account_delete.
-- 2. Limite de tentativas do código de convite: 10 códigos errados em
--    15 minutos bloqueiam novas conferências por um tempo.
--    Sem login, a contagem é pela conexão (endereço guardado embaralhado);
--    logado, é pela pessoa. Os registros somem depois de 1 dia.
--
-- Não apaga nem altera dados que já existem.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Excluir conta apaga o vínculo
-- ---------------------------------------------------------------------
create or replace function public.erase_affiliation_on_account_delete()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    delete from public.tb_user_affiliations where user_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists erase_affiliation_on_account_delete on public.tb_users;
create trigger erase_affiliation_on_account_delete
  after update of deleted_at on public.tb_users
  for each row execute function public.erase_affiliation_on_account_delete();

revoke all on function public.erase_affiliation_on_account_delete() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 2. Limite de tentativas do código de convite
-- ---------------------------------------------------------------------
create table public.tb_org_invite_attempts (
  id          bigint generated always as identity primary key,
  -- 'u:<id do usuário>' ou 'c:<sha256 do endereço da conexão>'
  attempt_key text not null,
  created_at  timestamptz not null default now()
);

comment on table public.tb_org_invite_attempts is
  'Códigos de convite errados, para limitar tentativas. Sem dados legíveis da pessoa; apagado após 1 dia.';

create index tb_org_invite_attempts_key_idx on public.tb_org_invite_attempts (attempt_key, created_at);

-- Ninguém lê nem grava direto: só as funções abaixo.
alter table public.tb_org_invite_attempts enable row level security;
revoke all on public.tb_org_invite_attempts from public, anon, authenticated;

-- Quem está tentando: a pessoa logada ou a conexão (embaralhada).
create or replace function public.org_invite_attempt_key()
returns text language plpgsql stable security definer set search_path = public, extensions, pg_temp as $$
declare
  v_headers json;
  v_ip text;
begin
  if auth.uid() is not null then
    return 'u:' || auth.uid()::text;
  end if;
  begin
    v_headers := nullif(current_setting('request.headers', true), '')::json;
  exception when others then
    v_headers := null;
  end;
  v_ip := coalesce(
    nullif(trim(v_headers ->> 'cf-connecting-ip'), ''),
    nullif(trim(split_part(v_headers ->> 'x-forwarded-for', ',', 1)), ''),
    'sem-endereco'  -- sem endereço: todas as tentativas sem login contam juntas
  );
  return 'c:' || encode(extensions.digest(v_ip, 'sha256'), 'hex');
end;
$$;

-- true quando já houve 10 códigos errados nos últimos 15 minutos.
create or replace function public.org_invite_blocked(p_key text)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select count(*) >= 10
    from public.tb_org_invite_attempts
   where attempt_key = p_key
     and created_at > now() - interval '15 minutes';
$$;

-- As funções originais passam a ser internas; o app continua chamando
-- os mesmos nomes, agora com o limite na frente.
alter function public.validate_org_invite(text) rename to validate_org_invite_unlimited;
alter function public.redeem_org_invite(text, text) rename to redeem_org_invite_unlimited;
revoke all on function public.validate_org_invite_unlimited(text) from public, anon, authenticated;
revoke all on function public.redeem_org_invite_unlimited(text, text) from public, anon, authenticated;

create or replace function public.validate_org_invite(p_code text)
returns jsonb language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_key text := public.org_invite_attempt_key();
  v_result jsonb;
begin
  if public.org_invite_blocked(v_key) then
    return jsonb_build_object('valid', false, 'reason', 'too_many_attempts');
  end if;
  v_result := public.validate_org_invite_unlimited(p_code);
  if v_result ->> 'reason' = 'not_found' then
    insert into public.tb_org_invite_attempts (attempt_key) values (v_key);
  end if;
  return v_result;
end;
$$;

create or replace function public.redeem_org_invite(p_code text, p_role_title text default null)
returns jsonb language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  v_key text;
  v_result jsonb;
begin
  if auth.uid() is null then
    return jsonb_build_object('valid', false, 'reason', 'not_authenticated');
  end if;
  v_key := public.org_invite_attempt_key();
  if public.org_invite_blocked(v_key) then
    return jsonb_build_object('valid', false, 'reason', 'too_many_attempts');
  end if;
  v_result := public.redeem_org_invite_unlimited(p_code, p_role_title);
  if v_result ->> 'reason' = 'not_found' then
    insert into public.tb_org_invite_attempts (attempt_key) values (v_key);
  end if;
  return v_result;
end;
$$;

revoke all on function public.org_invite_attempt_key() from public, anon, authenticated;
revoke all on function public.org_invite_blocked(text) from public, anon, authenticated;
revoke all on function public.validate_org_invite(text) from public;
revoke all on function public.redeem_org_invite(text, text) from public, anon;
grant execute on function public.validate_org_invite(text) to anon, authenticated;
grant execute on function public.redeem_org_invite(text, text) to authenticated;

-- Apaga as tentativas com mais de 1 dia, todo dia às 03:30 (Fortaleza) = 06:30 UTC
select cron.schedule(
  'limpar-tentativas-convite', '30 6 * * *',
  $cron$delete from public.tb_org_invite_attempts where created_at < now() - interval '1 day'$cron$
);

commit;

-- Para desfazer (ordem):
--   select cron.unschedule('limpar-tentativas-convite');
--   drop function public.validate_org_invite(text);
--   drop function public.redeem_org_invite(text, text);
--   alter function public.validate_org_invite_unlimited(text) rename to validate_org_invite;
--   alter function public.redeem_org_invite_unlimited(text, text) rename to redeem_org_invite;
--   (refazer os grants da migração 20261126120000, seção 7)
--   drop function public.org_invite_blocked(text);
--   drop function public.org_invite_attempt_key();
--   drop table public.tb_org_invite_attempts;
--   drop trigger erase_affiliation_on_account_delete on public.tb_users;
--   drop function public.erase_affiliation_on_account_delete();
