-- =====================================================================
-- Item 7: conta de teste "Rafael teste" sai das listas, sem apagar nada.
--
-- A conta (rafaelpab3+profteste@gmail.com) já está desativada, mas o perfil
-- de profissional continuava aprovado e visível, com 6 horários abertos.
--   * perfil de profissional: visibility_status -> 'low_profile' (oculto)
--   * 6 horários: deleted_at preenchido (apagamento lógico)
-- Sessões (16), pacientes (16) e histórico ficam como estão.
-- Antes, cópia das 7 linhas em tb_backup_conta_teste_20261126.
-- =====================================================================

begin;

create table public.tb_backup_conta_teste_20261126 (
  tabela     text not null,
  linha_id   uuid not null,
  dados      jsonb not null,
  copiado_em timestamptz not null default now()
);

comment on table public.tb_backup_conta_teste_20261126 is
  'Cópia das linhas alteradas pela migração 20261126150000 (conta de teste oculta). Pode ser apagada depois de conferida.';

-- Só a administração pelo painel do Supabase: ninguém lê pela API.
alter table public.tb_backup_conta_teste_20261126 enable row level security;
revoke all on public.tb_backup_conta_teste_20261126 from public, anon, authenticated;

insert into public.tb_backup_conta_teste_20261126 (tabela, linha_id, dados)
select 'tb_professionals', p.id, to_jsonb(p)
  from public.tb_professionals p
 where p.id = '01a19e09-8307-7144-aa98-cd968e83c0fc'
union all
select 'tb_appointment_times', t.id, to_jsonb(t)
  from public.tb_appointment_times t
 where t.professional_id = '01a19e09-8307-7144-aa98-cd968e83c0fc'
   and t.deleted_at is null;

update public.tb_professionals
   set visibility_status = 'low_profile'
 where id = '01a19e09-8307-7144-aa98-cd968e83c0fc';

update public.tb_appointment_times
   set deleted_at = now()
 where professional_id = '01a19e09-8307-7144-aa98-cd968e83c0fc'
   and deleted_at is null;

commit;

-- Para desfazer:
--   update public.tb_professionals set visibility_status = 'high_profile'
--    where id = '01a19e09-8307-7144-aa98-cd968e83c0fc';
--   update public.tb_appointment_times t set deleted_at = null
--     from public.tb_backup_conta_teste_20261126 b
--    where b.tabela = 'tb_appointment_times' and b.linha_id = t.id;
