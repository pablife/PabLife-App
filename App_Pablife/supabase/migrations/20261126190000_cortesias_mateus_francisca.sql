-- =====================================================================
-- Mateus Rodrigues de Sousa Borja e Francisca Rafaela Ferreira de Souza:
-- o plano "Lite" dado pelo painel em 27/10/2026 (admin_manual, R$ 0) era
-- cortesia, mas aparecia como "Plano pago". Passa a is_courtesy = true.
--
-- Acesso, datas (até 27/11/2026) e saldo não mudam. O aviso ao Customer.io
-- (cio_sync_courtesy) fica desligado só durante esta troca, para não ser
-- tratado como cortesia nova (e-mail de boas-vindas de novo).
-- Cópia das 2 linhas em tb_backup_assinaturas_20261126.
-- =====================================================================

begin;

insert into public.tb_backup_assinaturas_20261126 (linha_id, dados)
select s.id, to_jsonb(s)
  from public.tb_user_subscriptions s
 where s.id in ('01a17f4a-1fab-7569-a80a-a47b5732e116',  -- Mateus
                '01a17f49-b3e4-73ac-b4cc-4a1080cc7a6c')  -- Francisca
on conflict (linha_id) do nothing;

alter table public.tb_user_subscriptions disable trigger cio_sync_courtesy;

do $$
declare
  v_count integer;
begin
  update public.tb_user_subscriptions
     set is_courtesy = true,
         reason = 'Cortesia PABlife - Lite'
   where id in ('01a17f4a-1fab-7569-a80a-a47b5732e116',
                '01a17f49-b3e4-73ac-b4cc-4a1080cc7a6c')
     and is_courtesy = false;
  get diagnostics v_count = row_count;
  if v_count <> 2 then
    raise exception 'Esperava 2 assinaturas, encontrou %', v_count;
  end if;
end $$;

alter table public.tb_user_subscriptions enable trigger cio_sync_courtesy;

commit;

-- Para desfazer:
--   update public.tb_user_subscriptions s
--      set is_courtesy = false, reason = b.dados->>'reason'
--     from public.tb_backup_assinaturas_20261126 b
--    where b.linha_id = s.id
--      and s.id in ('01a17f4a-1fab-7569-a80a-a47b5732e116', '01a17f49-b3e4-73ac-b4cc-4a1080cc7a6c');
