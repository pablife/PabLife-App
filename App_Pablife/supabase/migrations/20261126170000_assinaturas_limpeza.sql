-- =====================================================================
-- Item 6: assinaturas "ativas" já vencidas e regra "plano novo encerra o
-- anterior".
--
-- O acesso e o saldo de consultas valem pelas datas (status 'active' ou
-- 'cancelled' dentro do período). Todas as linhas abaixo já venceram:
-- mudar o status não tira acesso nem saldo de ninguém; só corrige os
-- números de "ativos" no painel e nos relatórios.
--
-- 1. Limpeza (com backup em tb_backup_assinaturas_20261126):
--    status 'active' já vencidas (ou checkout de teste sem data),
--    fora as 3 pessoas que receberam cortesia de verdade
--    (Maria Clara, Mateus e Francisca), passam para 'cancelled' com
--    cancelled_at = data do vencimento. Em 26/11/2026: 86 linhas
--    (77 cortesias de teste, 7 planos manuais, 2 testes do "Plano 1").
--    O aviso ao Customer.io (cio_sync_courtesy) só dispara com 'active'.
-- 2. Regra: o banco já só aceita UMA assinatura 'active' por pessoa
--    (idx_uq_user_one_active_subscription). Por isso uma 'active' vencida
--    bloqueava qualquer plano novo (cupom, convênio, cortesia, renovação
--    mensal do convênio). Agora, ANTES de um plano ficar ativo, as outras
--    'active' da mesma pessoa passam para 'cancelled' (datas mantidas, para o
--    saldo seguir as regras atuais). Planos pagos recorrentes do Mercado Pago
--    ficam de fora (cancelar só aqui não para a cobrança lá): nesse caso o
--    plano novo continua sendo recusado, como hoje.
-- =====================================================================

begin;

create table public.tb_backup_assinaturas_20261126 (
  linha_id   uuid primary key,
  dados      jsonb not null,
  copiado_em timestamptz not null default now()
);

comment on table public.tb_backup_assinaturas_20261126 is
  'Cópia das assinaturas alteradas pela migração 20261126170000 (item 6). Pode ser apagada depois de conferida.';

alter table public.tb_backup_assinaturas_20261126 enable row level security;
revoke all on public.tb_backup_assinaturas_20261126 from public, anon, authenticated;

-- Quem fica de fora: as 3 cortesias de verdade.
create temporary table _cortesias_reais (user_id uuid primary key) on commit drop;
insert into _cortesias_reais values
  ('5698f6f0-8c71-49ba-b91f-b2a5975aecfa'),  -- Maria Clara de Alencar Santos
  ('f83a28e2-c191-4cd3-bffd-95f9f1cd5096'),  -- Mateus Rodrigues de Sousa Borja
  ('139ae0a8-ec08-402e-87bd-10f5f2f7eb43');  -- Francisca Rafaela Ferreira de Souza

create temporary table _alvo on commit drop as
select s.id
  from public.tb_user_subscriptions s
 where s.status = 'active'
   and s.user_id not in (select user_id from _cortesias_reais)
   and (s.end_date < now()
        or (s.end_date is null and s.mp_preapproval_id like 'TEMP-%'));

insert into public.tb_backup_assinaturas_20261126 (linha_id, dados)
select s.id, to_jsonb(s)
  from public.tb_user_subscriptions s
 where s.id in (select id from _alvo);

do $$
declare
  v_count integer;
begin
  update public.tb_user_subscriptions
     set status = 'cancelled',
         cancelled_at = coalesce(end_date, now())
   where id in (select id from _alvo);
  get diagnostics v_count = row_count;
  -- Conferido em 26/11/2026: 86. Se o banco mudou, para tudo.
  if v_count <> 86 then
    raise exception 'Esperava 86 assinaturas, encontrou %', v_count;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 2. Plano novo encerra o anterior
-- ---------------------------------------------------------------------
create or replace function public.close_previous_subscriptions()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if tg_op = 'UPDATE' and old.status = 'active' then
    return new;
  end if;
  -- Nunca impede gravar a assinatura nova.
  begin
    update public.tb_user_subscriptions s
       set status = 'cancelled',
           cancelled_at = now()
     where s.user_id = new.user_id
       and s.id is distinct from new.id
       and s.status = 'active'
       -- pago e recorrente no Mercado Pago: fica (cancelar só aqui não para a cobrança)
       and not (coalesce(s.transaction_amount, 0) > 0 and coalesce(s.has_preapproval, false));
  exception when others then
    null;
  end;
  return new;
end;
$$;

drop trigger if exists close_previous_subscriptions on public.tb_user_subscriptions;
create trigger close_previous_subscriptions
  before insert or update of status on public.tb_user_subscriptions
  for each row
  when (new.status = 'active')
  execute function public.close_previous_subscriptions();

revoke all on function public.close_previous_subscriptions() from public, anon, authenticated;

commit;

-- Para desfazer:
--   drop trigger close_previous_subscriptions on public.tb_user_subscriptions;
--   drop function public.close_previous_subscriptions();
--   update public.tb_user_subscriptions s
--      set status = b.dados->>'status',
--          cancelled_at = nullif(b.dados->>'cancelled_at', '')::timestamptz
--     from public.tb_backup_assinaturas_20261126 b
--    where b.linha_id = s.id;
