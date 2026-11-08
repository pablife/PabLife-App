-- Temas dos profissionais (filtro "Ansiedade", "Autoestima"...) e detalhes
-- do registro "Como estou hoje" da Saúde da Mulher.
-- Só acrescenta colunas: nada é apagado. As políticas de acesso já
-- existentes continuam valendo:
--   - tb_professionals: o profissional edita a própria linha; o admin, todas.
--   - tb_women_health_check_ins: só a própria pessoa lê e grava.

alter table public.tb_professionals
  add column if not exists topics text[] not null default '{}';

comment on column public.tb_professionals.topics is
  'Temas que o profissional atende (ex.: Ansiedade, Autoestima). Escolhidos pelo profissional ou pelo admin.';

alter table public.tb_women_health_check_ins
  add column if not exists symptoms text[] not null default '{}',
  add column if not exists energy smallint,
  add column if not exists sleep text,
  add column if not exists note text;

alter table public.tb_women_health_check_ins
  drop constraint if exists tb_women_health_check_ins_energy_check;
alter table public.tb_women_health_check_ins
  add constraint tb_women_health_check_ins_energy_check
  check (energy is null or energy between 1 and 5);

alter table public.tb_women_health_check_ins
  drop constraint if exists tb_women_health_check_ins_sleep_check;
alter table public.tb_women_health_check_ins
  add constraint tb_women_health_check_ins_sleep_check
  check (sleep is null or sleep in ('bem', 'mais_ou_menos', 'mal'));

alter table public.tb_women_health_check_ins
  drop constraint if exists tb_women_health_check_ins_note_check;
alter table public.tb_women_health_check_ins
  add constraint tb_women_health_check_ins_note_check
  check (note is null or char_length(note) <= 2000);
