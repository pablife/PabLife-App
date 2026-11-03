-- Meta diária: o check da meta vale só para o dia marcado, e o progresso
-- da meta no Dashboard passa a ser a % de dias cumpridos.
--
-- Antes: o primeiro check "concluía" a meta (aparecia feita de lá em diante)
-- e o Dashboard mostrava só o tempo decorrido até o prazo.
--
-- As duas trocas abaixo alteram apenas o trecho das metas; se o trecho não
-- for encontrado exatamente uma vez, nada é alterado.

-- 1) Planner (get_user_calendar_events): meta feita só no dia marcado.
do $$
declare
  def text := pg_get_functiondef('public.get_user_calendar_events(date)'::regprocedure);
  old_done text := 'CASE WHEN go.conclusion_date IS NOT NULL AND go.event_date >= go.conclusion_date THEN TRUE ELSE FALSE END AS is_completed';
  old_status text := 'CASE WHEN go.conclusion_date IS NOT NULL AND go.event_date >= go.conclusion_date THEN ''completed'' ELSE ''pending'' END AS status';
  done_on_day text := 'EXISTS (SELECT 1 FROM public.tb_activity_registers gar WHERE gar.activity_id = go.activity_id AND gar.deleted_at IS NULL AND gar.activity_date = go.event_date)';
begin
  if (length(def) - length(replace(def, old_done, ''))) / length(old_done) <> 1
     or (length(def) - length(replace(def, old_status, ''))) / length(old_status) <> 1 then
    raise exception 'Trecho das metas não encontrado em get_user_calendar_events';
  end if;
  def := replace(def, old_done, done_on_day || ' AS is_completed');
  def := replace(def, old_status,
    'CASE WHEN ' || done_on_day || ' THEN ''completed'' ELSE ''pending'' END AS status');
  execute def;
end;
$$;

-- 2) Dashboard (vw_weekly_task_activity_summary): % de dias cumpridos.
--    Dias da meta = da criação até o prazo (sem prazo: só o dia da criação),
--    como no planner.
do $$
declare
  def text := pg_get_viewdef('public.vw_weekly_task_activity_summary'::regclass, true);
  old_pct text := '''percentage'', gr.percentage)';
  new_pct text := '''percentage'', (
      SELECT LEAST(100::numeric, round(
               (SELECT count(DISTINCT gar.activity_date)
                  FROM tb_activity_registers gar
                 WHERE gar.activity_id = ga.id AND gar.deleted_at IS NULL)::numeric
               / GREATEST(1,
                   COALESCE(timezone(COALESCE(ga.timezone, ''UTC'')::text, ga.due_at),
                            timezone(COALESCE(ga.timezone, ''UTC'')::text, ga.created_at))::date
                   - timezone(COALESCE(ga.timezone, ''UTC'')::text, ga.created_at)::date
                   + 1)::numeric * 100::numeric, 2))
        FROM tb_activities ga
       WHERE ga.id = gr.goal_id))';
begin
  if (length(def) - length(replace(def, old_pct, ''))) / length(old_pct) <> 1 then
    raise exception 'Trecho das metas não encontrado em vw_weekly_task_activity_summary';
  end if;
  execute 'create or replace view public.vw_weekly_task_activity_summary as '
          || rtrim(replace(def, old_pct, new_pct), E'; \n');
end;
$$;
