-- Comissão do titular em percentual das primeiras mensalidades pagas por
-- cada usuário que veio pelo cupom (ex.: 5% das 3 primeiras). Depois disso
-- aquele usuário não gera mais comissão. Substitui o valor fixo por assinante.

alter table public.tb_coupon_owners
  add column if not exists commission_percent numeric(5, 2) not null default 0
    check (commission_percent >= 0 and commission_percent <= 100),
  add column if not exists commission_months integer not null default 3
    check (commission_months between 1 and 36);

-- Mudam as colunas devolvidas: recria as funções.
drop function if exists public.admin_coupon_users();
drop function if exists public.my_coupon_owner_users();
drop function if exists public.my_coupon_owner();
drop function if exists public.coupon_user_metrics();

-- Base dos relatórios: um registro por uso de cupom (sem os de teste).
-- paid_payments: mensalidades pagas depois do cupom; commission_base: soma
-- das primeiras N (N = commission_months do titular), sobre a qual incide o
-- percentual. Estornos não contam (deixam de estar "approved").
create function public.coupon_user_metrics()
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
  converted_at timestamptz,
  paid_payments integer,
  commission_payments integer,
  commission_base numeric
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
    pay.first_paid_at,
    coalesce(pay.paid, 0),
    coalesce(pay.comm_n, 0),
    coalesce(pay.base, 0)
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
    select
      min(p.paid_at) as first_paid_at,
      count(*)::integer as paid,
      count(*) filter (where p.rn <= coalesce(o.commission_months, 3))::integer as comm_n,
      sum(p.amount) filter (where p.rn <= coalesce(o.commission_months, 3)) as base
    from (
      select
        tx.transaction_amount as amount,
        tx.mp_date_approved as paid_at,
        row_number() over (order by tx.mp_date_approved) as rn
      from public.tb_subscription_transactions tx
      join public.tb_user_subscriptions us on us.id = tx.user_subscription_id
      where us.user_id = r.user_id
        and tx.status = 'approved'
        and coalesce(tx.transaction_amount, 0) > 0
        and tx.mp_date_approved >= r.redeemed_at
    ) p
  ) pay on true
  where not r.is_test;
$$;

revoke all on function public.coupon_user_metrics() from public, anon, authenticated;

create function public.admin_coupon_users()
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
  converted_at timestamptz,
  paid_payments integer,
  commission_payments integer,
  commission_base numeric
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

create function public.my_coupon_owner()
returns table (
  id uuid,
  name text,
  kind text,
  commission_percent numeric,
  commission_months integer
)
language sql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
  select o.id, o.name, o.kind, o.commission_percent, o.commission_months
  from public.tb_coupon_owners o
  where o.access_user_id = auth.uid() and o.is_active;
$$;

create function public.my_coupon_owner_users()
returns table (
  display_name text,
  coupon_code text,
  plan_name text,
  redeemed_at timestamptz,
  access_until timestamptz,
  subscription_status text,
  consultations integer,
  first_consultation_at timestamptz,
  converted_at timestamptz,
  paid_payments integer,
  commission_payments integer,
  commission_base numeric
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
    m.converted_at,
    m.paid_payments,
    m.commission_payments,
    m.commission_base
  from public.coupon_user_metrics() m
  join public.tb_coupon_owners o on o.id = m.owner_id
  where o.access_user_id = auth.uid() and o.is_active
  order by m.redeemed_at desc;
$$;

revoke all on function public.admin_coupon_users() from public, anon;
revoke all on function public.my_coupon_owner() from public, anon;
revoke all on function public.my_coupon_owner_users() from public, anon;
grant execute on function public.admin_coupon_users() to authenticated;
grant execute on function public.my_coupon_owner() to authenticated;
grant execute on function public.my_coupon_owner_users() to authenticated;
