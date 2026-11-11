-- Gestação (Saúde da Mulher): acompanhamento, registros e conteúdo semana a
-- semana. Só acrescenta: nada existente é apagado ou alterado.
--
-- Dados de saúde (LGPD):
--   - a usuária lê e grava só os próprios dados;
--   - o profissional só lê registros marcados para compartilhar, e só das
--     pacientes dele (is_my_patient);
--   - nada público: fotos num bucket privado, anon sem acesso.
--
-- A semana atual é calculada no banco (get_my_pregnancy), não no app.
-- Os textos do conteúdo só chegam ao app com reviewed_by_professional = true
-- (get_pregnancy_weeks); medidas e ilustrações aparecem sempre, como
-- estimativa.

-- ------------------------------------------------------------ gestações

create table if not exists public.tb_pregnancies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.tb_users(id) on delete cascade,
  dum date not null,
  dpp date generated always as (dum + 280) stored,
  status text not null default 'active',
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tb_pregnancies_status_check check (status in ('active', 'ended')),
  constraint tb_pregnancies_dum_check check (
    dum >= date '2000-01-01'
    and dum <= (now() at time zone 'America/Sao_Paulo')::date
  )
);

comment on table public.tb_pregnancies is
  'Saúde da Mulher: gestação acompanhada (DUM, data provável do parto). Privado da usuária.';

-- Uma gestação ativa por usuária.
create unique index if not exists tb_pregnancies_one_active_idx
  on public.tb_pregnancies (user_id) where status = 'active';

drop trigger if exists set_updated_at_trigger_tb_pregnancies
  on public.tb_pregnancies;
create trigger set_updated_at_trigger_tb_pregnancies
  before update on public.tb_pregnancies
  for each row execute function public.set_updated_at();

alter table public.tb_pregnancies enable row level security;

drop policy if exists "Own pregnancies" on public.tb_pregnancies;
create policy "Own pregnancies"
  on public.tb_pregnancies
  for all
  to authenticated
  using (user_id = public.get_my_uid())
  with check (user_id = public.get_my_uid());

revoke all on public.tb_pregnancies from anon;
grant select, insert, update on public.tb_pregnancies to authenticated;

-- ------------------------------------------------------------ registros

create table if not exists public.tb_pregnancy_records (
  id uuid primary key default gen_random_uuid(),
  pregnancy_id uuid not null references public.tb_pregnancies(id) on delete cascade,
  user_id uuid not null references public.tb_users(id) on delete cascade,
  record_date date not null,
  type text not null,
  peso_mae numeric(5, 2),
  pressao text,
  bcf smallint,
  peso_estimado_bebe integer,
  comprimento_estimado numeric(4, 1),
  como_estou text,
  notes text,
  photo_url text,
  shared_with_professional boolean not null default false,
  shared_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tb_pregnancy_records_type_check check (
    type in ('consulta', 'ultrassom', 'exame', 'movimentos', 'sintoma', 'anotacao')
  ),
  constraint tb_pregnancy_records_date_check check (
    record_date >= date '2000-01-01'
    and record_date <= (now() at time zone 'America/Sao_Paulo')::date + 1
  ),
  constraint tb_pregnancy_records_peso_mae_check check (
    peso_mae is null or peso_mae between 30 and 250
  ),
  constraint tb_pregnancy_records_pressao_check check (
    pressao is null or pressao ~ '^[0-9]{2,3}/[0-9]{2,3}$'
  ),
  constraint tb_pregnancy_records_bcf_check check (
    bcf is null or bcf between 50 and 250
  ),
  constraint tb_pregnancy_records_peso_bebe_check check (
    peso_estimado_bebe is null or peso_estimado_bebe between 0 and 7000
  ),
  constraint tb_pregnancy_records_comprimento_check check (
    comprimento_estimado is null or comprimento_estimado between 0 and 70
  ),
  constraint tb_pregnancy_records_como_estou_check check (
    como_estou is null
    or como_estou in ('Bem', 'Cansada', 'Enjoada', 'Ansiosa', 'Emotiva')
  ),
  constraint tb_pregnancy_records_notes_check check (
    notes is null or char_length(notes) <= 2000
  ),
  constraint tb_pregnancy_records_photo_check check (
    photo_url is null or char_length(photo_url) <= 300
  )
);

comment on table public.tb_pregnancy_records is
  'Saúde da Mulher: registros da gestação (consulta, ultrassom, exame, movimentos, sintoma, anotação). Privado da usuária; o profissional vê só os compartilhados.';

create index if not exists tb_pregnancy_records_pregnancy_idx
  on public.tb_pregnancy_records (pregnancy_id, record_date desc);
create index if not exists tb_pregnancy_records_user_idx
  on public.tb_pregnancy_records (user_id, record_date desc);

drop trigger if exists set_updated_at_trigger_tb_pregnancy_records
  on public.tb_pregnancy_records;
create trigger set_updated_at_trigger_tb_pregnancy_records
  before update on public.tb_pregnancy_records
  for each row execute function public.set_updated_at();

alter table public.tb_pregnancy_records enable row level security;

drop policy if exists "Own pregnancy records" on public.tb_pregnancy_records;
create policy "Own pregnancy records"
  on public.tb_pregnancy_records
  for all
  to authenticated
  using (user_id = public.get_my_uid())
  with check (
    user_id = public.get_my_uid()
    and exists (
      select 1 from public.tb_pregnancies p
      where p.id = pregnancy_id and p.user_id = public.get_my_uid()
    )
  );

drop policy if exists "Professional reads shared pregnancy records"
  on public.tb_pregnancy_records;
create policy "Professional reads shared pregnancy records"
  on public.tb_pregnancy_records
  for select
  to authenticated
  using (shared_with_professional and public.is_my_patient(user_id));

revoke all on public.tb_pregnancy_records from anon;
grant select, insert, update, delete on public.tb_pregnancy_records to authenticated;

-- ------------------------------------------------------------ conteúdo

create table if not exists public.tb_pregnancy_weeks (
  week smallint primary key,
  tamanho_cm numeric(4, 1),
  peso_g numeric(6, 1),
  comparacao text,
  texto_bebe text,
  texto_mae text,
  texto_consulta text,
  sinais_de_alerta text,
  image_url text,
  reviewed_by_professional boolean not null default false,
  reviewed_by text,
  reviewed_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint tb_pregnancy_weeks_week_check check (week between 4 and 40)
);

comment on table public.tb_pregnancy_weeks is
  'Conteúdo da gestação semana a semana. Textos em linhas "Título. Frase"; só chegam ao app quando reviewed_by_professional = true.';

drop trigger if exists set_updated_at_trigger_tb_pregnancy_weeks
  on public.tb_pregnancy_weeks;
create trigger set_updated_at_trigger_tb_pregnancy_weeks
  before update on public.tb_pregnancy_weeks
  for each row execute function public.set_updated_at();

-- Sem leitura direta: o app usa get_pregnancy_weeks().
alter table public.tb_pregnancy_weeks enable row level security;
revoke all on public.tb_pregnancy_weeks from anon, authenticated;

-- ------------------------------------------------------------ funções

-- Gestação ativa da usuária, com semana e dias calculados no fuso de São
-- Paulo. ref_week = semana da ilustração (8, 12, ..., 40) mais próxima.
create or replace function public.get_my_pregnancy()
returns table (
  id uuid,
  dum date,
  dpp date,
  week integer,
  day integer,
  days_left integer,
  trimester integer,
  ref_week integer
)
language sql
stable
security invoker
set search_path = public
as $$
  with t as (
    select (now() at time zone 'America/Sao_Paulo')::date as today
  )
  select
    p.id,
    p.dum,
    p.dpp,
    ((t.today - p.dum) / 7)::integer as week,
    ((t.today - p.dum) % 7)::integer as day,
    greatest(p.dpp - t.today, 0)::integer as days_left,
    case
      when (t.today - p.dum) / 7 <= 13 then 1
      when (t.today - p.dum) / 7 <= 27 then 2
      else 3
    end as trimester,
    least(greatest(round(((t.today - p.dum) / 7)::numeric / 4) * 4, 8), 40)::integer
      as ref_week
  from public.tb_pregnancies p, t
  where p.user_id = public.get_my_uid() and p.status = 'active'
  limit 1;
$$;

revoke all on function public.get_my_pregnancy() from public, anon;
grant execute on function public.get_my_pregnancy() to authenticated;

-- Conteúdo das semanas. Medidas e imagem sempre; textos só se revisados.
create or replace function public.get_pregnancy_weeks()
returns table (
  week smallint,
  tamanho_cm numeric,
  peso_g numeric,
  comparacao text,
  texto_bebe text,
  texto_mae text,
  texto_consulta text,
  sinais_de_alerta text,
  image_url text,
  reviewed boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    w.week,
    w.tamanho_cm,
    w.peso_g,
    w.comparacao,
    case when w.reviewed_by_professional then w.texto_bebe end,
    case when w.reviewed_by_professional then w.texto_mae end,
    case when w.reviewed_by_professional then w.texto_consulta end,
    case when w.reviewed_by_professional then w.sinais_de_alerta end,
    w.image_url,
    w.reviewed_by_professional
  from public.tb_pregnancy_weeks w
  where auth.uid() is not null
  order by w.week;
$$;

revoke all on function public.get_pregnancy_weeks() from public, anon;
grant execute on function public.get_pregnancy_weeks() to authenticated;

-- ------------------------------------------------------------ notificações

-- Agenda na fila existente (tb_notification_schedule, enviada pelo
-- OneSignal a cada 5 min): "Você entrou na semana X" (no dia em que a
-- semana começa, 10h) e, a cada 4 semanas, o lembrete de registrar consulta
-- ou ultrassom (19h). Ao encerrar a gestação ou mudar a DUM, os avisos ainda
-- pendentes ficam como "skipped" (nada é apagado). O texto não leva dados
-- de saúde além da semana.
create or replace function public.schedule_pregnancy_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  w integer;
  at_ts timestamptz;
begin
  if tg_op = 'UPDATE'
     and new.dum = old.dum
     and new.status = old.status then
    return new;
  end if;

  update public.tb_notification_schedule
     set status = 'skipped',
         error = case when new.status = 'ended'
                      then 'gestação encerrada'
                      else 'gestação alterada' end
   where target_user_id = new.user_id
     and campaign in ('gestacao-semana', 'gestacao-lembrete')
     and status = 'pending';

  if new.status <> 'active' then
    return new;
  end if;

  for w in 5..40 loop
    at_ts := ((new.dum + w * 7)::timestamp + time '10:00')
             at time zone 'America/Sao_Paulo';
    if at_ts > now() then
      insert into public.tb_notification_schedule
        (campaign, scheduled_at, title, message, status, target_user_id)
      values (
        'gestacao-semana', at_ts,
        'Semana ' || w || ' da gestação',
        'Você entrou na semana ' || w || '. Veja como o bebê está crescendo.',
        'pending', new.user_id
      );
    end if;

    if w % 4 = 2 then
      at_ts := ((new.dum + w * 7 + 3)::timestamp + time '19:00')
               at time zone 'America/Sao_Paulo';
      if at_ts > now() then
        insert into public.tb_notification_schedule
          (campaign, scheduled_at, title, message, status, target_user_id)
        values (
          'gestacao-lembrete', at_ts,
          'Minha gestação',
          'Teve consulta ou ultrassom? Registre no app para acompanhar tudo.',
          'pending', new.user_id
        );
      end if;
    end if;
  end loop;

  return new;
end;
$$;

revoke all on function public.schedule_pregnancy_notifications() from public, anon, authenticated;

drop trigger if exists schedule_pregnancy_notifications_trigger
  on public.tb_pregnancies;
create trigger schedule_pregnancy_notifications_trigger
  after insert or update of dum, status on public.tb_pregnancies
  for each row execute function public.schedule_pregnancy_notifications();

-- ------------------------------------------------------------ storage

-- Fotos de ultrassom e exame: privado. Caminho "<id da usuária>/<arquivo>".
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pregnancy-photos', 'pregnancy-photos', false, 10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do nothing;

-- Ilustrações do bebê (conteúdo genérico, sem dado pessoal).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pregnancy-illustrations', 'pregnancy-illustrations', true, 2097152,
  array['image/png', 'image/webp', 'image/jpeg']
)
on conflict (id) do nothing;

drop policy if exists "Own pregnancy photos" on storage.objects;
create policy "Own pregnancy photos"
  on storage.objects
  for all
  to authenticated
  using (
    bucket_id = 'pregnancy-photos'
    and (storage.foldername(name))[1] = public.get_my_uid()::text
  )
  with check (
    bucket_id = 'pregnancy-photos'
    and (storage.foldername(name))[1] = public.get_my_uid()::text
  );

drop policy if exists "Professional reads shared pregnancy photos" on storage.objects;
create policy "Professional reads shared pregnancy photos"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'pregnancy-photos'
    and exists (
      select 1 from public.tb_pregnancy_records r
      where r.photo_url = storage.objects.name
        and r.shared_with_professional
        and public.is_my_patient(r.user_id)
    )
  );
