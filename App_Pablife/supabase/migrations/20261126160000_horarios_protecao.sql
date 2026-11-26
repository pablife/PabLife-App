-- =====================================================================
-- Item 3: regra de proteção dos horários. Não altera nenhuma linha.
--
-- O app guarda dois tipos de horário:
--   * semanal: ligado a uma regra de recorrência com o dia da semana
--     (week_select já é obrigatório no banco, de 0 a 6);
--   * avulso:  sem regra, com a data (due_at).
-- Os ~490 horários "sem dia da semana" são avulsos com data: estão certos.
-- Em 26/11/2026: 804 horários, todos com regra ou data. Esta migração só
-- impede que um horário sem regra e sem data seja gravado.
-- =====================================================================

begin;

alter table public.tb_appointment_times
  add constraint tb_appointment_times_rule_or_date_chk
  check (appointment_recurrence_rule_id is not null or due_at is not null);

commit;

-- Para desfazer:
--   alter table public.tb_appointment_times drop constraint tb_appointment_times_rule_or_date_chk;
