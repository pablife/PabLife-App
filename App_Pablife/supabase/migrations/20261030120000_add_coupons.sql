-- Cupons de desconto. Por enquanto o único tipo é "dias grátis": a assinatura
-- começa ativa sem cobrança e a primeira mensalidade fica para depois do período.

create table if not exists public.tb_coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  description text,
  free_days integer not null default 30 check (free_days > 0),
  valid_from timestamptz,
  valid_until timestamptz,
  max_uses integer check (max_uses is null or max_uses > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists tb_coupons_code_key on public.tb_coupons (upper(code));

create table if not exists public.tb_coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.tb_coupons (id),
  user_id uuid not null,
  user_subscription_id uuid,
  plan_id uuid,
  is_test boolean not null default false,
  redeemed_at timestamptz not null default now(),
  unique (coupon_id, user_id)
);

create index if not exists tb_coupon_redemptions_coupon_idx
  on public.tb_coupon_redemptions (coupon_id);

-- Só o servidor (service role) lê e grava direto; o app usa validate_coupon.
alter table public.tb_coupons enable row level security;
alter table public.tb_coupon_redemptions enable row level security;

-- Confere um cupom para o usuário logado, sem usar. Devolve
-- {valid, reason, free_days, coupon_id}; reason: not_found, inactive,
-- not_started, expired, exhausted, already_used.
create or replace function public.validate_coupon(p_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_coupon public.tb_coupons;
  v_uses integer;
begin
  select * into v_coupon
  from public.tb_coupons
  where upper(code) = upper(trim(p_code));

  if not found then
    return jsonb_build_object('valid', false, 'reason', 'not_found');
  end if;
  if not v_coupon.is_active then
    return jsonb_build_object('valid', false, 'reason', 'inactive');
  end if;
  if v_coupon.valid_from is not null and now() < v_coupon.valid_from then
    return jsonb_build_object('valid', false, 'reason', 'not_started');
  end if;
  if v_coupon.valid_until is not null and now() > v_coupon.valid_until then
    return jsonb_build_object('valid', false, 'reason', 'expired');
  end if;
  if v_coupon.max_uses is not null then
    select count(*) into v_uses
    from public.tb_coupon_redemptions
    where coupon_id = v_coupon.id and not is_test;
    if v_uses >= v_coupon.max_uses then
      return jsonb_build_object('valid', false, 'reason', 'exhausted');
    end if;
  end if;
  if exists (
    select 1 from public.tb_coupon_redemptions
    where coupon_id = v_coupon.id and user_id = auth.uid()
  ) then
    return jsonb_build_object('valid', false, 'reason', 'already_used');
  end if;

  return jsonb_build_object(
    'valid', true,
    'coupon_id', v_coupon.id,
    'free_days', v_coupon.free_days
  );
end;
$$;

revoke all on function public.validate_coupon(text) from public, anon;
grant execute on function public.validate_coupon(text) to authenticated, service_role;
