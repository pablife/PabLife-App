-- =====================================================================
-- Item 3: regra de proteção dos horários. Não altera nenhuma linha.
--
-- O app guarda dois tipos de horário:
--   * semanal: ligado a uma regra de recorrência com o dia da semana;
--   * avulso:  sem regra, com a data (due_at).
-- Os ~490 horários "sem dia da semana" são avulsos com data: estão certos.
-- Em 26/11/2026: 221 regras, todas com dia; 804 horários, todos com regra
-- ou data. Esta migração só impede que um horário errado seja gravado.
-- =====================================================================

begin;

-- Toda regra semanal tem dia da semana (0 a 6 já era conferido).
alter table public.tb_appointment_recurrence_rules
  alter column week_select set not null;

-- Todo horário é semanal (tem regra) ou avulso (tem data).
alter table public.tb_appointment_times
  add constraint tb_appointment_times_rule_or_date_chk
  check (appointment_recurrence_rule_id is not null or due_at is not null);

commit;

-- Para desfazer:
--   alter table public.tb_appointment_recurrence_rules alter column week_select drop not null;
--   alter table public.tb_appointment_times drop constraint tb_appointment_times_rule_or_date_chk;
