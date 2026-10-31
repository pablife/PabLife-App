-- Cupom sem Mercado Pago: libera o plano escolhido por N dias, sem cartão e sem
-- recorrência. A assinatura fica com valor 0, sem preapproval, id "COUPON-..."
-- e ligada ao cupom (coupon_id). Ao fim do período o acesso termina sozinho e
-- a pessoa assina normalmente se quiser continuar.
--
-- Não usa is_courtesy de propósito: a cortesia dispara a automação
-- "consulta_gratuita_liberada" no Customer.io.

alter table public.tb_user_subscriptions
  add column if not exists coupon_id uuid references public.tb_coupons (id);

-- Ciclos de cupom contam consultas do plano como os de cortesia (sem
-- transação aprovada). Ajuste pontual nas funções de saldo/acesso.
do $$
declare
  v_fn text;
  v_def text;
  v_new text;
begin
  foreach v_fn in array array[
    'get_user_subscription_access_info',
    'get_user_subscription_access_info_v2',
    'get_user_consultation_balances',
    'get_user_consultation_balances_v2'
  ] loop
    v_def := pg_get_functiondef(format('public.%I()', v_fn)::regprocedure);
    if position('is_coupon' in v_def) > 0 then
      continue; -- já ajustada
    end if;
    v_new := v_def;
    v_new := replace(v_new,
      'us.is_courtesy,',
      'us.is_courtesy, (us.coupon_id IS NOT NULL) AS is_coupon,');
    v_new := replace(v_new,
      'AND (NOT us.is_courtesy OR us.status = ''active'')',
      'AND (NOT (us.is_courtesy OR us.coupon_id IS NOT NULL) OR us.status = ''active'')');
    v_new := replace(v_new,
      'WHERE c.is_courtesy',
      'WHERE c.is_courtesy OR c.is_coupon');
    if v_new = v_def
      or position('AS is_coupon' in v_new) = 0
      or position('OR c.is_coupon' in v_new) = 0
      or position('us.coupon_id IS NOT NULL) OR us.status' in v_new) = 0 then
      raise exception 'Não foi possível ajustar %', v_fn;
    end if;
    execute v_new;
  end loop;
end;
$$;

create or replace function public.redeem_coupon(p_code text, p_plan_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_user_id uuid := auth.uid();
  v_coupon public.tb_coupons;
  v_plan public.tb_subscription_plans;
  v_uses integer;
  v_ref text;
  v_start timestamptz := now();
  v_end timestamptz;
  v_subscription_id uuid;
begin
  if v_user_id is null then
    return jsonb_build_object('valid', false, 'reason', 'not_authenticated');
  end if;

  -- Trava o cupom para o limite de usos valer mesmo com resgates simultâneos.
  select * into v_coupon
  from public.tb_coupons
  where upper(code) = upper(trim(p_code))
  for update;

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
    where coupon_id = v_coupon.id and user_id = v_user_id
  ) then
    return jsonb_build_object('valid', false, 'reason', 'already_used');
  end if;

  select * into v_plan
  from public.tb_subscription_plans
  where id = p_plan_id and deleted_at is null;
  if not found then
    return jsonb_build_object('valid', false, 'reason', 'plan_not_found');
  end if;

  -- Quem já tem plano valendo, ou uma assinatura paga ativa/em andamento, não
  -- usa cupom: evita duas assinaturas ao mesmo tempo.
  if exists (
    select 1 from public.tb_user_subscriptions
    where user_id = v_user_id
      and (
        status = 'pending'
        or (status = 'active' and not is_courtesy and coupon_id is null)
        or (
          status in ('active', 'cancelled')
          and start_date is not null and end_date is not null
          and now() between start_date and end_date
        )
      )
  ) then
    return jsonb_build_object('valid', false, 'reason', 'has_subscription');
  end if;

  v_end := v_start + make_interval(days => v_coupon.free_days);
  v_ref := 'COUPON-' || gen_random_uuid()::text;

  insert into public.tb_user_subscriptions (
    user_id, plan_id, mp_preapproval_id, external_reference, status, reason,
    frequency, frequency_type, transaction_amount, currency_id,
    start_date, end_date, started_at, renewed_at,
    has_first_payment, has_preapproval, is_courtesy, coupon_id
  ) values (
    v_user_id, v_plan.id, v_ref, v_ref, 'active',
    v_plan.reason || ' (cupom ' || upper(v_coupon.code) || ')',
    1, 'months', 0, 'BRL',
    v_start, v_end, v_start, v_start,
    false, false, false, v_coupon.id
  )
  returning id into v_subscription_id;

  insert into public.tb_coupon_redemptions (
    coupon_id, user_id, user_subscription_id, plan_id, is_test
  ) values (
    v_coupon.id, v_user_id, v_subscription_id, v_plan.id, false
  );

  return jsonb_build_object(
    'valid', true,
    'free_days', v_coupon.free_days,
    'ends_at', v_end,
    'user_subscription_id', v_subscription_id
  );
end;
$$;

revoke all on function public.redeem_coupon(text, uuid) from public, anon;
grant execute on function public.redeem_coupon(text, uuid) to authenticated;
