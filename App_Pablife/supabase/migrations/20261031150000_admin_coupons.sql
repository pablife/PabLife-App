-- Painel de cupons: titulares (influenciadores, parceiros...), gestão de
-- cupons pelo admin e relatórios de resultado (primeira consulta e
-- conversão em assinante). O titular pode entrar no painel e ver só os
-- números dele, sem dados pessoais dos usuários.

create table if not exists public.tb_coupon_owners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null default 'influencer'
    check (kind in ('influencer', 'parceiro', 'empresa', 'profissional', 'outro')),
  instagram text,
  email text,
  phone text,
  notes text,
  -- Comissão paga por usuário que virou assinante pagante.
  commission_per_conversion numeric(10, 2) not null default 0
    check (commission_per_conversion >= 0),
  -- Conta (tb_users) com que o titular entra no painel.
  access_user_id uuid references public.tb_users (id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists tb_coupon_owners_access_user_key
  on public.tb_coupon_owners (access_user_id)
  where access_user_id is not null;

alter table public.tb_coupons
  add column if not exists owner_id uuid references public.tb_coupon_owners (id);

alter table public.tb_coupon_owners enable row level security;

create policy "Admin view coupon owners" on public.tb_coupon_owners
  for select to authenticated using (public.is_admin());
create policy "Admin create coupon owners" on public.tb_coupon_owners
  for insert to authenticated with check (public.is_admin());
create policy "Admin update coupon owners" on public.tb_coupon_owners
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Admin view coupons" on public.tb_coupons
  for select to authenticated using (public.is_admin());
create policy "Admin create coupons" on public.tb_coupons
  for insert to authenticated with check (public.is_admin());
create policy "Admin update coupons" on public.tb_coupons
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Admin view coupon redemptions" on public.tb_coupon_redemptions
  for select to authenticated using (public.is_admin());

-- Base dos relatórios: um registro por uso de cupom (sem os de teste), com
-- consultas feitas depois do uso e a primeira mensalidade paga.
-- Interna: só as funções abaixo a chamam.
create or replace function public.coupon_user_metrics()
returns table (
  redemption_id uuid,
  user_id uuid,
  full_name text,
  email text,
  coupon_id uuid,
  coupon_code text,
  owner_id uuid,
  owner_name text,
  plan_name text,
  redeemed_at timestamptz,
  access_until timestamptz,
  subscription_status text,
  consultations integer,
  no_shows integer,
  first_consultation_at timestamptz,
  last_consultation_at timestamptz,
  converted_at timestamptz
)
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  select
    r.id,
    r.user_id,
    u.full_name::text,
    u.email::text,
    c.id,
    c.code,
    o.id,
    o.name,
    sp.reason::text,
    r.redeemed_at,
    s.end_date,
    s.status,
    coalesce(ap.done, 0),
    coalesce(ap.missed, 0),
    ap.first_at,
    ap.last_at,
    pay.paid_at
  from public.tb_coupon_redemptions r
  join public.tb_coupons c on c.id = r.coupon_id
  left join public.tb_coupon_owners o on o.id = c.owner_id
  left join public.tb_users u on u.id = r.user_id
  left join public.tb_subscription_plans sp on sp.id = r.plan_id
  left join public.tb_user_subscriptions s on s.id = r.user_subscription_id
  left join lateral (
    select
      count(*) filter (where a.status = 'completed')::integer as done,
      count(*) filter (where a.status = 'no_show')::integer as missed,
      min(a.start_of_scheduled_window) filter (where a.status = 'completed') as first_at,
      max(a.start_of_scheduled_window) filter (where a.status = 'completed') as last_at
    from public.tb_appointments a
    where a.scheduled_by = r.user_id
      and a.deleted_at is null
      and a.start_of_scheduled_window >= r.redeemed_at
  ) ap on true
  left join lateral (
    select min(tx.mp_date_approved) as paid_at
    from public.tb_subscription_transactions tx
    join public.tb_user_subscriptions us on us.id = tx.user_subscription_id
    where us.user_id = r.user_id
      and tx.status = 'approved'
      and coalesce(tx.transaction_amount, 0) > 0
      and tx.mp_date_approved >= r.redeemed_at
  ) pay on true
  where not r.is_test;
$$;

revoke all on function public.coupon_user_metrics() from public, anon, authenticated;

-- Admin: todos os usuários que entraram por cupom, com os resultados.
create or replace function public.admin_coupon_users()
returns table (
  redemption_id uuid,
  user_id uuid,
  full_name text,
  email text,
  coupon_id uuid,
  coupon_code text,
  owner_id uuid,
  owner_name text,
  plan_name text,
  redeemed_at timestamptz,
  access_until timestamptz,
  subscription_status text,
  consultations integer,
  no_shows integer,
  first_consultation_at timestamptz,
  last_consultation_at timestamptz,
  converted_at timestamptz
)
language plpgsql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if not public.is_admin() then
    raise exception 'not allowed';
  end if;
  return query select * from public.coupon_user_metrics() m
    order by m.redeemed_at desc;
end;
$$;

-- Titular: qual titular é a conta logada (vazio se não for titular).
create or replace function public.my_coupon_owner()
returns table (id uuid, name text, kind text, commission_per_conversion numeric)
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  select o.id, o.name, o.kind, o.commission_per_conversion
  from public.tb_coupon_owners o
  where o.access_user_id = auth.uid() and o.is_active;
$$;

-- Titular: os usuários que ele trouxe, sem e-mail e só com primeiro nome +
-- inicial do sobrenome.
create or replace function public.my_coupon_owner_users()
returns table (
  display_name text,
  coupon_code text,
  plan_name text,
  redeemed_at timestamptz,
  access_until timestamptz,
  subscription_status text,
  consultations integer,
  first_consultation_at timestamptz,
  converted_at timestamptz
)
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  select
    trim(
      split_part(coalesce(m.full_name, ''), ' ', 1) || ' ' ||
      coalesce(
        left(nullif(regexp_replace(m.full_name, '^\S+\s*', ''), ''), 1) || '.',
        ''
      )
    ),
    m.coupon_code,
    m.plan_name,
    m.redeemed_at,
    m.access_until,
    m.subscription_status,
    m.consultations,
    m.first_consultation_at,
    m.converted_at
  from public.coupon_user_metrics() m
  join public.tb_coupon_owners o on o.id = m.owner_id
  where o.access_user_id = auth.uid() and o.is_active
  order by m.redeemed_at desc;
$$;

-- Titular: os próprios cupons.
create or replace function public.my_coupon_owner_coupons()
returns table (code text, free_days integer, valid_until timestamptz, is_active boolean)
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  select c.code, c.free_days, c.valid_until, c.is_active
  from public.tb_coupons c
  join public.tb_coupon_owners o on o.id = c.owner_id
  where o.access_user_id = auth.uid() and o.is_active
  order by c.created_at desc;
$$;

revoke all on function public.admin_coupon_users() from public, anon;
revoke all on function public.my_coupon_owner() from public, anon;
revoke all on function public.my_coupon_owner_users() from public, anon;
revoke all on function public.my_coupon_owner_coupons() from public, anon;
grant execute on function public.admin_coupon_users() to authenticated;
grant execute on function public.my_coupon_owner() to authenticated;
grant execute on function public.my_coupon_owner_users() to authenticated;
grant execute on function public.my_coupon_owner_coupons() to authenticated;
