-- Vínculo institucional: data de início do contrato da organização
-- Só adiciona coluna e regra; não apaga nem altera dados.
-- O fim (contract_ends_at) continua sendo o que limita o plano liberado.

alter table public.tb_organizations
  add column if not exists contract_starts_at date;

comment on column public.tb_organizations.contract_starts_at is
  'Início do contrato com a organização (informativo; prefeituras costumam ter 12 meses)';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tb_organizations_contract_dates_chk'
      and conrelid = 'public.tb_organizations'::regclass
  ) then
    alter table public.tb_organizations
      add constraint tb_organizations_contract_dates_chk
      check (contract_starts_at is null or contract_ends_at is null or contract_ends_at >= contract_starts_at);
  end if;
end $$;
