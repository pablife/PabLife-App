-- Justificativa quando o profissional marca a consulta como
-- "Cancelada/remarcada" (status = 'cancelled').
alter table public.tb_appointments
  add column if not exists cancellation_reason text;

comment on column public.tb_appointments.cancellation_reason is
  'Justificativa do profissional ao marcar a consulta como cancelada/remarcada.';
