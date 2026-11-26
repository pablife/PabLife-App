-- =====================================================================
-- Pablife · Vínculo institucional do usuário (RASCUNHO — NÃO APLICADO)
-- Projeto Supabase: PabLife-dev (produção)
--
-- O que cria:
--   1. tb_organizations          prefeituras, câmaras, empresas e outros
--   2. tb_user_affiliations      um registro por usuário: vínculo, organização, cargo
--   3. tb_user_subscriptions.organization_id   coluna nova e opcional (plano do contrato)
--   4. Funções (RPC) para o app e para o painel administrativo
--   5. Renovação automática diária do plano do convênio (pg_cron), com pausa
--      por falta de uso (60 dias sem consulta) e por 2 faltas seguidas
--   6. Regras de acesso (RLS)
--
-- Não altera nem apaga nada que já existe. A única mudança em tabela antiga
-- é uma coluna nova, opcional e vazia em tb_user_subscriptions.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Organizações
-- ---------------------------------------------------------------------
create table public.tb_organizations (
  id               uuid primary key default gen_random_uuid(),
  name             text not null check (length(trim(name)) between 2 and 160),
  kind             text not null check (kind in ('prefeitura', 'camara', 'empresa', 'outro')),
  city             text,
  state            char(2) check (state is null or state ~ '^[A-Z]{2}$'),
  -- Código de convite: único, sem diferenciar maiúsculas (citext). Ex.: PMFORTALEZA-7K2
  invite_code      citext unique check (invite_code is null or invite_code ~* '^[A-Z0-9-]{4,30}$'),
  -- Plano do contrato (opcional). Só o código de convite libera o plano.
  plan_id          uuid references public.tb_subscription_plans(id),
  plan_days        integer not null default 30 check (plan_days between 1 and 366),
  contract_ends_at date,          -- se preenchido, o plano liberado não passa desta data
  is_active        boolean not null default true,
  created_by       uuid references public.tb_users(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table  public.tb_organizations is 'Órgãos públicos e empresas parceiras aos quais o usuário pode se vincular';
comment on column public.tb_organizations.kind is 'prefeitura | camara | empresa | outro';
comment on column public.tb_organizations.invite_code is 'Código de convite (único). Fica oculto para usuários comuns: só é validado por RPC';
comment on column public.tb_organizations.plan_id is 'Plano liberado pelo código de convite (opcional)';
comment on column public.tb_organizations.plan_days is 'Dias de plano a cada ativação pelo código';
comment on column public.tb_organizations.contract_ends_at is 'Fim do contrato; o plano liberado não passa desta data';

create index tb_organizations_kind_active_idx on public.tb_organizations (kind) where is_active;

create trigger tb_organizations_set_updated_at
  before update on public.tb_organizations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- 2. Vínculo do usuário (um registro por usuário)
-- ---------------------------------------------------------------------
create table public.tb_user_affiliations (
  user_id                uuid primary key references public.tb_users(id) on delete cascade,
  kind                   text not null check (kind in ('servidor_publico', 'empresa_parceira', 'particular')),
  organization_id        uuid references public.tb_organizations(id),
  suggested_organization text check (suggested_organization is null or length(trim(suggested_organization)) between 2 and 160),
  role_title             text check (role_title is null or length(trim(role_title)) <= 120),
  suggestion_status      text check (suggestion_status in ('pendente', 'aprovada', 'descartada')),
  -- Pausa do plano do convênio (renovação automática): ver renew_org_plans()
  plan_paused_at         timestamptz,
  plan_pause_reason      text check (plan_pause_reason in ('sem_uso', 'faltas')),
  plan_resumed_at        timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  -- Particular não tem organização, sugestão nem cargo
  constraint tb_user_affiliations_particular_chk
    check (kind <> 'particular' or (organization_id is null and suggested_organization is null and role_title is null)),
  -- Toda sugestão tem um status, e só sugestão tem status
  constraint tb_user_affiliations_suggestion_chk
    check ((suggested_organization is null) = (suggestion_status is null))
);

comment on table  public.tb_user_affiliations is 'Vínculo institucional de cada usuário, para relatórios anônimos por organização';
comment on column public.tb_user_affiliations.kind is 'servidor_publico | empresa_parceira | particular';
comment on column public.tb_user_affiliations.suggested_organization is 'Texto digitado em "Não encontrei minha organização"';
comment on column public.tb_user_affiliations.suggestion_status is 'pendente | aprovada | descartada (só existe quando há sugestão)';
comment on column public.tb_user_affiliations.plan_paused_at is 'Quando o plano do convênio foi pausado (sem uso ou faltas); vazio = não pausado';
comment on column public.tb_user_affiliations.plan_pause_reason is 'sem_uso (sem consulta em 60 dias) | faltas (2 faltas seguidas)';
comment on column public.tb_user_affiliations.plan_resumed_at is 'Última vez que a pessoa reativou o plano do convênio';

create index tb_user_affiliations_org_idx on public.tb_user_affiliations (organization_id);
create index tb_user_affiliations_pending_idx on public.tb_user_affiliations (created_at) where suggestion_status = 'pendente';

create trigger tb_user_affiliations_set_updated_at
  before update on public.tb_user_affiliations
  for each row execute function public.set_updated_at();

-- Quais tipos de organização combinam com cada vínculo
create or replace function public.affiliation_kind_matches(p_kind text, p_org_kind text)
returns boolean language sql immutable as $$
  select case p_kind
    when 'servidor_publico' then p_org_kind in ('prefeitura', 'camara', 'outro')
    when 'empresa_parceira' then p_org_kind in ('empresa', 'outro')
    else false
  end;
$$;

-- Proteção do registro quando quem grava é o próprio usuário (não admin):
--  * particular: limpa organização, sugestão e cargo
--  * só aceita organização ativa e do tipo certo
--  * sugestão sempre entra como "pendente" e sem organização
--  * o usuário não consegue aprovar nem descartar a própria sugestão
create or replace function public.protect_user_affiliation()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_org_kind text;
begin
  if public.is_admin() or current_setting('pablife.affiliation_rpc', true) = 'on' then
    return new;
  end if;

  -- A pausa do plano só muda pelas funções do sistema
  if tg_op = 'INSERT' then
    new.plan_paused_at := null; new.plan_pause_reason := null; new.plan_resumed_at := null;
  else
    new.plan_paused_at := old.plan_paused_at; new.plan_pause_reason := old.plan_pause_reason; new.plan_resumed_at := old.plan_resumed_at;
  end if;

  if new.kind = 'particular' then
    new.organization_id := null;
    new.suggested_organization := null;
    new.suggestion_status := null;
    new.role_title := null;
    return new;
  end if;

  new.suggested_organization := nullif(trim(new.suggested_organization), '');
  new.role_title := nullif(trim(new.role_title), '');

  if new.suggested_organization is not null then
    -- Sugestão nova ou alterada volta para a fila
    if tg_op = 'INSERT' or new.suggested_organization is distinct from old.suggested_organization then
      new.suggestion_status := 'pendente';
      new.organization_id := null;
    else
      new.suggestion_status := old.suggestion_status;
    end if;
  else
    new.suggestion_status := null;
  end if;

  if new.organization_id is not null then
    select kind into v_org_kind from public.tb_organizations where id = new.organization_id and is_active;
    if v_org_kind is null then
      raise exception 'Organização inexistente ou inativa' using errcode = 'P0001';
    end if;
    if not public.affiliation_kind_matches(new.kind, v_org_kind) then
      raise exception 'Organização não combina com o tipo de vínculo' using errcode = 'P0001';
    end if;
  end if;

  return new;
end;
$$;

create trigger tb_user_affiliations_protect
  before insert or update on public.tb_user_affiliations
  for each row execute function public.protect_user_affiliation();

-- ---------------------------------------------------------------------
-- 3. Assinatura liberada pelo contrato da organização (coluna nova, opcional)
-- ---------------------------------------------------------------------
alter table public.tb_user_subscriptions
  add column if not exists organization_id uuid references public.tb_organizations(id);

comment on column public.tb_user_subscriptions.organization_id is 'Preenchido quando o plano foi liberado pelo código de convite de uma organização';

create index if not exists tb_user_subscriptions_org_idx
  on public.tb_user_subscriptions (organization_id) where organization_id is not null;

-- ---------------------------------------------------------------------
-- 4. Regras de acesso (RLS)
-- ---------------------------------------------------------------------
alter table public.tb_organizations enable row level security;
alter table public.tb_user_affiliations enable row level security;

-- Organizações: só a administração lê a tabela inteira (com o código) e grava.
-- Usuários logados veem a lista de organizações ativas pela função list_organizations(),
-- que não devolve o código de convite. Não há política de DELETE: desativa, não apaga.
create policy "Admin view organizations" on public.tb_organizations
  for select to authenticated using (public.is_admin());
create policy "Admin create organizations" on public.tb_organizations
  for insert to authenticated with check (public.is_admin());
create policy "Admin update organizations" on public.tb_organizations
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Vínculo: o usuário lê e grava só o próprio; a administração lê e corrige todos.
create policy "Own affiliation read" on public.tb_user_affiliations
  for select to authenticated using (user_id = public.get_my_uid() or public.is_admin());
create policy "Own affiliation create" on public.tb_user_affiliations
  for insert to authenticated with check (user_id = public.get_my_uid() or public.is_admin());
create policy "Own affiliation update" on public.tb_user_affiliations
  for update to authenticated
  using (user_id = public.get_my_uid() or public.is_admin())
  with check (user_id = public.get_my_uid() or public.is_admin());

-- ---------------------------------------------------------------------
-- 5. Funções para o app
-- ---------------------------------------------------------------------

-- Lista de organizações ativas, com busca (sem acento) e filtro por tipo. Sem o código.
-- Liberada também para quem ainda não entrou (anon): a pergunta aparece no cadastro,
-- antes de a conta existir.
create or replace function public.list_organizations(p_kinds text[] default null, p_search text default null)
returns table (id uuid, name text, kind text, city text, state text)
language sql stable security definer set search_path = public, pg_temp as $$
  select o.id, o.name, o.kind, o.city, o.state::text
  from public.tb_organizations o
  where o.is_active
    and (p_kinds is null or o.kind = any (p_kinds))
    -- cada palavra digitada precisa aparecer no nome ou na cidade (sem acento, sem maiúscula)
    and not exists (
      select 1
      from unnest(string_to_array(unaccent(lower(coalesce(trim(p_search), ''))), ' ')) w
      where w <> ''
        and unaccent(lower(o.name || ' ' || coalesce(o.city, '') || ' ' || coalesce(o.state, ''))) not like '%' || w || '%'
    )
  order by o.name
  limit 50;
$$;

-- Confere o código de convite sem gravar nada (para preencher a tela).
-- Liberada para anon pelo mesmo motivo; devolve só nome, tipo, cidade e o nome do plano.
create or replace function public.validate_org_invite(p_code text)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  v_org public.tb_organizations;
  v_plan_name text;
begin
  select * into v_org from public.tb_organizations where invite_code = trim(p_code)::citext;
  if not found then
    return jsonb_build_object('valid', false, 'reason', 'not_found');
  end if;
  if not v_org.is_active then
    return jsonb_build_object('valid', false, 'reason', 'inactive');
  end if;
  if v_org.contract_ends_at is not null and v_org.contract_ends_at < current_date then
    return jsonb_build_object('valid', false, 'reason', 'expired');
  end if;
  select reason into v_plan_name from public.tb_subscription_plans where id = v_org.plan_id and deleted_at is null;
  return jsonb_build_object(
    'valid', true,
    'organization', jsonb_build_object('id', v_org.id, 'name', v_org.name, 'kind', v_org.kind, 'city', v_org.city, 'state', v_org.state),
    'affiliation_kind', case when v_org.kind = 'empresa' then 'empresa_parceira' else 'servidor_publico' end,
    'plan_name', v_plan_name
  );
end;
$$;

-- Usa o código de convite: vincula o usuário à organização e, se houver plano no contrato,
-- libera o plano (mesma lógica do cupom: assinatura ativa de valor zero).
create or replace function public.redeem_org_invite(p_code text, p_role_title text default null)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_org public.tb_organizations;
  v_plan public.tb_subscription_plans;
  v_kind text;
  v_start timestamptz := now();
  v_end timestamptz;
  v_ref text;
  v_sub uuid;
begin
  if v_user is null then
    return jsonb_build_object('valid', false, 'reason', 'not_authenticated');
  end if;
  select * into v_org from public.tb_organizations where invite_code = trim(p_code)::citext for share;
  if not found then
    return jsonb_build_object('valid', false, 'reason', 'not_found');
  end if;
  if not v_org.is_active or (v_org.contract_ends_at is not null and v_org.contract_ends_at < current_date) then
    return jsonb_build_object('valid', false, 'reason', 'inactive');
  end if;

  v_kind := case when v_org.kind = 'empresa' then 'empresa_parceira' else 'servidor_publico' end;

  perform set_config('pablife.affiliation_rpc', 'on', true);
  insert into public.tb_user_affiliations (user_id, kind, organization_id, role_title)
  values (v_user, v_kind, v_org.id, nullif(trim(p_role_title), ''))
  on conflict (user_id) do update
    set kind = excluded.kind,
        organization_id = excluded.organization_id,
        role_title = coalesce(excluded.role_title, public.tb_user_affiliations.role_title),
        suggested_organization = null,
        suggestion_status = null,
        -- usar o código de novo também reativa um plano pausado
        plan_paused_at = null,
        plan_pause_reason = null,
        plan_resumed_at = case when public.tb_user_affiliations.plan_paused_at is not null then now() else public.tb_user_affiliations.plan_resumed_at end;
  perform set_config('pablife.affiliation_rpc', 'off', true);

  if v_org.plan_id is null then
    return jsonb_build_object('valid', true, 'linked', true, 'plan_granted', false);
  end if;

  select * into v_plan from public.tb_subscription_plans where id = v_org.plan_id and deleted_at is null;
  if not found then
    return jsonb_build_object('valid', true, 'linked', true, 'plan_granted', false, 'reason', 'plan_not_found');
  end if;

  -- Já tem plano válido (pago, cupom ou desta mesma organização): só vincula
  if exists (
    select 1 from public.tb_user_subscriptions
    where user_id = v_user
      and (status = 'pending'
        or (status in ('active', 'cancelled') and start_date is not null and end_date is not null and now() between start_date and end_date))
  ) then
    return jsonb_build_object('valid', true, 'linked', true, 'plan_granted', false, 'reason', 'has_subscription');
  end if;

  v_end := v_start + make_interval(days => v_org.plan_days);
  if v_org.contract_ends_at is not null then
    v_end := least(v_end, (v_org.contract_ends_at + 1)::timestamptz);
  end if;
  v_ref := 'ORG-' || gen_random_uuid()::text;

  insert into public.tb_user_subscriptions (
    user_id, plan_id, mp_preapproval_id, external_reference, status, reason,
    frequency, frequency_type, transaction_amount, currency_id,
    start_date, end_date, started_at, renewed_at,
    has_first_payment, has_preapproval, is_courtesy, organization_id
  ) values (
    v_user, v_plan.id, v_ref, v_ref, 'active',
    v_plan.reason || ' (convênio ' || v_org.name || ')',
    1, 'months', 0, 'BRL',
    v_start, v_end, v_start, v_start,
    false, false, false, v_org.id
  ) returning id into v_sub;

  return jsonb_build_object('valid', true, 'linked', true, 'plan_granted', true,
    'plan_name', v_plan.reason, 'ends_at', v_end, 'user_subscription_id', v_sub);
end;
$$;

-- ---------------------------------------------------------------------
-- 6. Funções para o painel administrativo
-- ---------------------------------------------------------------------

-- Resolve sugestões pendentes (uma ou várias de uma vez):
--   'criar'     cria a organização com os dados de p_new e vincula os usuários
--   'juntar'    vincula os usuários a uma organização existente (p_organization_id)
--   'descartar' marca a sugestão como descartada; o usuário fica sem organização
create or replace function public.resolve_org_suggestion(
  p_user_ids uuid[],
  p_action text,
  p_organization_id uuid default null,
  p_new jsonb default null
) returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_org uuid := p_organization_id;
  v_count integer;
begin
  if not public.is_admin() then
    raise exception 'Apenas administradores' using errcode = '42501';
  end if;
  if p_action not in ('criar', 'juntar', 'descartar') then
    raise exception 'Ação inválida: %', p_action;
  end if;

  if p_action = 'criar' then
    insert into public.tb_organizations (name, kind, city, state, invite_code, plan_id, created_by)
    values (
      trim(p_new->>'name'), p_new->>'kind', nullif(trim(p_new->>'city'), ''),
      nullif(upper(trim(p_new->>'state')), ''), nullif(upper(trim(p_new->>'invite_code')), ''),
      nullif(p_new->>'plan_id', '')::uuid, public.get_my_uid()
    ) returning id into v_org;
  elsif p_action = 'juntar' and v_org is null then
    raise exception 'Informe a organização para juntar';
  end if;

  if p_action = 'descartar' then
    update public.tb_user_affiliations
       set suggestion_status = 'descartada', organization_id = null
     where user_id = any (p_user_ids) and suggestion_status = 'pendente';
  else
    update public.tb_user_affiliations
       set suggestion_status = 'aprovada', organization_id = v_org
     where user_id = any (p_user_ids) and suggestion_status = 'pendente';
  end if;
  get diagnostics v_count = row_count;

  return jsonb_build_object('ok', true, 'updated', v_count, 'organization_id', v_org);
end;
$$;

-- ---------------------------------------------------------------------
-- 6b. Renovação automática do plano do convênio
--   Roda todo dia (pg_cron). Para quem ativou o plano pelo código:
--   * 2 faltas seguidas (desde a ativação ou a última reativação): o plano
--     pausa na hora (a assinatura do convênio é encerrada) e a pessoa é avisada.
--   * Na renovação: se não é o 1º mês e não houve consulta realizada nos
--     últimos 60 dias, não renova e pausa (sem_uso).
--   * Nos outros casos, renova por plan_days, sem passar do fim do contrato.
--   * Quem tem outro plano válido (pago ou cupom) não recebe renovação.
--   A pessoa reativa com resume_org_plan() (botão "Reativar plano" no app).
-- ---------------------------------------------------------------------

-- Cria um período do plano do convênio (uso interno)
create or replace function public.grant_org_plan_period(p_user uuid, p_org uuid, p_start timestamptz)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_org public.tb_organizations;
  v_plan public.tb_subscription_plans;
  v_end timestamptz;
  v_ref text := 'ORG-' || gen_random_uuid()::text;
  v_sub uuid;
begin
  select * into v_org from public.tb_organizations where id = p_org;
  select * into v_plan from public.tb_subscription_plans where id = v_org.plan_id and deleted_at is null;
  if v_plan.id is null then return null; end if;
  v_end := p_start + make_interval(days => v_org.plan_days);
  if v_org.contract_ends_at is not null then
    v_end := least(v_end, (v_org.contract_ends_at + 1)::timestamptz);
  end if;
  if v_end <= p_start then return null; end if;
  insert into public.tb_user_subscriptions (
    user_id, plan_id, mp_preapproval_id, external_reference, status, reason,
    frequency, frequency_type, transaction_amount, currency_id,
    start_date, end_date, started_at, renewed_at,
    has_first_payment, has_preapproval, is_courtesy, organization_id
  ) values (
    p_user, v_plan.id, v_ref, v_ref, 'active',
    v_plan.reason || ' (convênio ' || v_org.name || ')',
    1, 'months', 0, 'BRL',
    p_start, v_end, p_start, now(),
    false, false, false, v_org.id
  ) returning id into v_sub;
  return v_sub;
end;
$$;

create or replace function public.renew_org_plans()
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  r record;
  v_last public.tb_user_subscriptions;
  v_since timestamptz;
  v_periods integer;
  v_renewed integer := 0;
  v_paused_faltas integer := 0;
  v_paused_uso integer := 0;
begin
  perform set_config('pablife.affiliation_rpc', 'on', true);
  for r in
    select a.user_id, a.plan_resumed_at, o.id as org_id, o.name as org_name
    from public.tb_user_affiliations a
    join public.tb_organizations o on o.id = a.organization_id
    where a.plan_paused_at is null
      and o.is_active and o.plan_id is not null
      and (o.contract_ends_at is null or o.contract_ends_at >= current_date)
  loop
    select * into v_last from public.tb_user_subscriptions
     where user_id = r.user_id and organization_id = r.org_id
     order by end_date desc nulls last limit 1;
    continue when v_last.id is null;              -- nunca ativou pelo código
    continue when v_last.status = 'cancelled';    -- cancelou ou já pausado

    -- Regra das faltas: as 2 últimas consultas com desfecho foram faltas
    v_since := greatest(coalesce(r.plan_resumed_at, '-infinity'::timestamptz),
                        (select min(start_date) from public.tb_user_subscriptions where user_id = r.user_id and organization_id = r.org_id));
    if (select count(*) = 2 and bool_and(status = 'no_show') from (
          select status from public.tb_appointments
           where scheduled_by = r.user_id and status in ('completed', 'no_show')
             and start_of_scheduled_window >= v_since and start_of_scheduled_window <= now()
           order by start_of_scheduled_window desc limit 2) x) then
      update public.tb_user_subscriptions
         set status = 'cancelled', cancelled_at = now(), end_date = greatest(start_date, least(end_date, now()))
       where user_id = r.user_id and organization_id = r.org_id and end_date > now();
      update public.tb_user_affiliations set plan_paused_at = now(), plan_pause_reason = 'faltas' where user_id = r.user_id;
      insert into public.tb_notifications (user_id, title, message, metadata)
      values (r.user_id, 'Seu plano do convênio foi pausado',
              'Você faltou às duas últimas consultas. Para continuar, abra o app e toque em "Reativar plano" no Perfil.',
              jsonb_build_object('type', 'org_plan_paused', 'reason', 'faltas'));
      v_paused_faltas := v_paused_faltas + 1;
      continue;
    end if;

    -- Renovação: só quando o período atual termina em até 1 dia
    continue when v_last.end_date > now() + interval '1 day';

    -- Já tem outro plano válido (pago ou cupom): não renova
    continue when exists (
      select 1 from public.tb_user_subscriptions
       where user_id = r.user_id and organization_id is distinct from r.org_id
         and status in ('active', 'cancelled') and start_date is not null and end_date is not null
         and now() between start_date and end_date);

    select count(*) into v_periods from public.tb_user_subscriptions where user_id = r.user_id and organization_id = r.org_id;

    -- Regra do uso: fora do 1º mês, precisa de 1 consulta realizada nos últimos 60 dias
    if v_periods >= 2 and not exists (
        select 1 from public.tb_appointments
         where scheduled_by = r.user_id and status = 'completed'
           and start_of_scheduled_window >= now() - interval '60 days') then
      update public.tb_user_affiliations set plan_paused_at = now(), plan_pause_reason = 'sem_uso' where user_id = r.user_id;
      insert into public.tb_notifications (user_id, title, message, metadata)
      values (r.user_id, 'Seu plano do convênio está pausado',
              'Você não teve consultas nos últimos 60 dias. Quer continuar? Abra o app e toque em "Reativar plano" no Perfil.',
              jsonb_build_object('type', 'org_plan_paused', 'reason', 'sem_uso'));
      v_paused_uso := v_paused_uso + 1;
      continue;
    end if;

    if public.grant_org_plan_period(r.user_id, r.org_id, greatest(v_last.end_date, now())) is not null then
      v_renewed := v_renewed + 1;
    end if;
  end loop;
  perform set_config('pablife.affiliation_rpc', 'off', true);
  return jsonb_build_object('renewed', v_renewed, 'paused_faltas', v_paused_faltas, 'paused_sem_uso', v_paused_uso);
end;
$$;

-- O usuário reativa o próprio plano pausado
create or replace function public.resume_org_plan()
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_aff public.tb_user_affiliations;
  v_org public.tb_organizations;
  v_sub uuid;
begin
  if v_user is null then
    return jsonb_build_object('ok', false, 'reason', 'not_authenticated');
  end if;
  select * into v_aff from public.tb_user_affiliations where user_id = v_user;
  if v_aff.plan_paused_at is null then
    return jsonb_build_object('ok', false, 'reason', 'not_paused');
  end if;
  select * into v_org from public.tb_organizations where id = v_aff.organization_id;
  if v_org.id is null or not v_org.is_active or v_org.plan_id is null
     or (v_org.contract_ends_at is not null and v_org.contract_ends_at < current_date) then
    return jsonb_build_object('ok', false, 'reason', 'contract_inactive');
  end if;
  perform set_config('pablife.affiliation_rpc', 'on', true);
  update public.tb_user_affiliations
     set plan_paused_at = null, plan_pause_reason = null, plan_resumed_at = now()
   where user_id = v_user;
  perform set_config('pablife.affiliation_rpc', 'off', true);
  -- Começa quando terminar o período que ainda estiver valendo (sem sobrepor)
  v_sub := public.grant_org_plan_period(v_user, v_org.id, greatest(now(), coalesce((
    select max(end_date) from public.tb_user_subscriptions
     where user_id = v_user and organization_id = v_org.id and status = 'active'), now())));
  return jsonb_build_object('ok', v_sub is not null, 'user_subscription_id', v_sub,
    'ends_at', (select end_date from public.tb_user_subscriptions where id = v_sub));
end;
$$;

-- Todo dia às 03:15 (Fortaleza) = 06:15 UTC
select cron.schedule('renovar-planos-convenio', '15 6 * * *', $cron$select public.renew_org_plans()$cron$);

-- ---------------------------------------------------------------------
-- 7. Permissões das funções
-- ---------------------------------------------------------------------
revoke all on function public.list_organizations(text[], text) from public;
revoke all on function public.validate_org_invite(text) from public;
revoke all on function public.redeem_org_invite(text, text) from public, anon;
revoke all on function public.resolve_org_suggestion(uuid[], text, uuid, jsonb) from public, anon;
revoke all on function public.protect_user_affiliation() from public, anon, authenticated;
revoke all on function public.grant_org_plan_period(uuid, uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.renew_org_plans() from public, anon, authenticated;
revoke all on function public.resume_org_plan() from public, anon;
grant execute on function public.resume_org_plan() to authenticated;

grant execute on function public.list_organizations(text[], text) to anon, authenticated;
grant execute on function public.validate_org_invite(text) to anon, authenticated;
grant execute on function public.redeem_org_invite(text, text) to authenticated;
grant execute on function public.resolve_org_suggestion(uuid[], text, uuid, jsonb) to authenticated;

commit;

-- =====================================================================
-- Para desfazer (se precisar):
--   select cron.unschedule('renovar-planos-convenio');
--   drop function public.resume_org_plan();
--   drop function public.renew_org_plans();
--   drop function public.grant_org_plan_period(uuid, uuid, timestamptz);
--   drop function public.resolve_org_suggestion(uuid[], text, uuid, jsonb);
--   drop function public.redeem_org_invite(text, text);
--   drop function public.validate_org_invite(text);
--   drop function public.list_organizations(text[], text);
--   drop table public.tb_user_affiliations;
--   drop function public.protect_user_affiliation();
--   drop function public.affiliation_kind_matches(text, text);
--   alter table public.tb_user_subscriptions drop column organization_id;
--   drop table public.tb_organizations;
-- =====================================================================
