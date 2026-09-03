-- Activate the Comando de Crescimento ESF across agent memory and scheduling.

create or replace function public.growth_start_experiment(
  p_experiment_id uuid,
  p_actor_agent_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_experiment public.growth_experiments%rowtype;
  v_actor_slug text;
  v_running integer;
  v_limit integer;
begin
  select * into v_experiment
  from public.growth_experiments where id = p_experiment_id for update;
  if v_experiment.id is null then raise exception 'Growth experiment not found'; end if;
  if v_experiment.status <> 'planned' then raise exception 'Only planned experiments can start'; end if;

  select slug into v_actor_slug from public.agents_registry where id = p_actor_agent_id and is_active;
  if v_actor_slug is null then raise exception 'Active actor agent not found'; end if;
  if v_actor_slug <> 'admin-total' and p_actor_agent_id <> v_experiment.owner_agent_id then
    raise exception 'Only Leonardo or the experiment owner can start it';
  end if;

  select coalesce((operating_principles->>'max_active_experiments')::integer, 5)
    into v_limit from public.growth_system_config where singleton;
  select count(*)::integer into v_running
  from public.growth_experiments where status = 'running';
  if v_running >= v_limit then raise exception 'Active growth experiment limit reached'; end if;

  if v_experiment.baseline_value is null or v_experiment.target_value is null
     or nullif(btrim(v_experiment.metric_key), '') is null
     or v_experiment.ends_at <= now() then
    raise exception 'Experiment needs baseline, target, metric and a future deadline';
  end if;
  if not exists (
    select 1 from public.growth_experiment_agents
    where experiment_id = v_experiment.id and responsibility = 'owner'
  ) then raise exception 'Experiment needs an owner assignment'; end if;

  update public.growth_experiments
  set status = 'running', stage = case when stage = 'discover' then 'discover' else 'execute' end,
      starts_at = coalesce(starts_at, now()),
      metadata = metadata || jsonb_build_object(
        'started_by_agent_slug', v_actor_slug,
        'activated_at', now()
      )
  where id = v_experiment.id;

  update public.agent_mission_tasks
  set priority = 'high',
      metadata = metadata || jsonb_build_object(
        'growth_execution_status', 'ready_for_agent',
        'growth_started_at', now(),
        'growth_started_by', v_actor_slug
      ),
      updated_at = now()
  where metadata->>'growth_experiment_id' = v_experiment.id::text
    and status = 'backlog';

  insert into public.agent_mission_events(
    tenant_id, event_type, actor_agent_id, task_id, title, detail, payload
  )
  select
    v_experiment.tenant_id, 'growth_experiment_started', p_actor_agent_id, task.id,
    'Experimento ativado pelo Comando de Crescimento ESF', v_experiment.title,
    jsonb_build_object(
      'growth_experiment_id', v_experiment.id,
      'growth_objective_id', v_experiment.objective_id,
      'metric_key', v_experiment.metric_key,
      'baseline', v_experiment.baseline_value,
      'target', v_experiment.target_value,
      'deadline', v_experiment.ends_at
    )
  from public.agent_mission_tasks task
  where task.metadata->>'growth_experiment_id' = v_experiment.id::text
  limit 1;

  return jsonb_build_object(
    'experiment_id', v_experiment.id,
    'status', 'running',
    'active_experiments', v_running + 1,
    'portfolio_limit', v_limit
  );
end;
$function$;

revoke all on function public.growth_start_experiment(uuid,uuid) from public;
grant execute on function public.growth_start_experiment(uuid,uuid) to service_role;

create or replace function public.growth_command_dashboard()
returns jsonb
language sql
stable
set search_path to ''
as $function$
  select jsonb_build_object(
    'product', (select to_jsonb(config) from public.growth_system_config config where singleton),
    'scorecard', coalesce((
      select jsonb_agg(to_jsonb(score) order by
        case score.status when 'active' then 1 when 'achieved' then 2 else 3 end,
        score.pillar, score.title
      ) from public.growth_command_scorecard score
    ), '[]'::jsonb),
    'experiments', coalesce((
      select jsonb_agg(to_jsonb(board) order by
        case board.status when 'running' then 1 when 'planned' then 2 else 3 end,
        board.ends_at
      ) from public.growth_command_experiment_board board
    ), '[]'::jsonb),
    'alerts', jsonb_build_object(
      'objectives_off_target', (
        select count(*) from public.growth_objectives objective
        where objective.status = 'active' and objective.current_value is not null
      ),
      'experiments_running', (
        select count(*) from public.growth_experiments experiment where experiment.status = 'running'
      ),
      'experiments_overdue', (
        select count(*) from public.growth_experiments experiment
        where experiment.status in ('planned', 'running', 'paused') and experiment.ends_at < now()
      ),
      'learnings_waiting_leonardo', (
        select count(*) from public.growth_learnings learning where learning.status = 'candidate'
      )
    ),
    'generated_at', now()
  );
$function$;

grant execute on function public.growth_command_dashboard() to authenticated, service_role;

-- Give each core agent its own durable operating contract. The scope is narrow:
-- the agent and Leonardo can read it; unrelated agent memory is not broadened.
insert into public.agent_notes(
  agent_id, title, slug, content, tags, metadata, collection, source_name,
  responsible, valid_until, allowed_audiences, approval_status, priority
)
select
  agent.id,
  'Contrato operacional — Comando de Crescimento ESF',
  'growth-operating-contract-v1',
  case agent.slug
    when 'admin-total' then 'Você governa o portfólio de crescimento. Mantenha no máximo cinco experimentos ativos, resolva dependências e decida escalar, iterar ou parar somente com baseline, resultado e evidência. Rejeite relatório sem consequência operacional.'
    when 'estrategista' then 'Converta sinais dos agentes em escolhas de portfólio. Toda recomendação deve explicitar trade-off, impacto esperado, métrica, prazo e o que deixará de ser feito.'
    when 'tracao' then 'Responda por demanda qualificada, CAC e conversão de aquisição. Campanha só é aprendizado quando sua origem chega até visita e matrícula; alcance isolado não prova resultado.'
    when 'comercial' then 'Responda pelo funil lead→agendamento→comparecimento→matrícula. Localize o maior vazamento por unidade e melhore uma etapa por experimento, preservando experiência e margem.'
    when 'bastia' then 'Responda por frequência, onboarding, experiência e evasão. Intervenções devem usar coortes comparáveis, evitar desconto predatório e medir retenção real.'
    when 'operacao' then 'Transforme o experimento aprovado em execução consistente nas unidades. Registre aderência, capacidade, falhas e efeitos colaterais antes de recomendar escala.'
    when 'cifra' then 'Valide retorno, margem, payback e risco financeiro. Não aprove escala baseada apenas em leads, alcance ou receita bruta sem custo e conversão final.'
    when 'plataforma' then 'Garanta que mídia, CRM, EVO e operação produzam dados conciliáveis. Identificadores, origem, timestamps, cobertura, qualidade e ausência de dados devem ser observáveis.'
    when 'espia' then 'Meça liderança local com fontes públicas repetíveis: procura, avaliações, share of voice, demanda qualificada e preferência. Separe fato, proxy e inferência.'
    when 'concorrencia' then 'Converta movimentos públicos dos concorrentes em risco ou oportunidade mensurável para Salto. Não copie peças nem confunda atividade pública com desempenho comprovado.'
    when 'pauta' then 'Conteúdo deve servir a um estágio do funil e a um objetivo ativo. Defina público, ação esperada e sinal de avanço; calendário e volume não são resultado por si só.'
    when 'reels' then 'Vídeo deve ter hipótese de público, gancho, retenção e ação seguinte. Use resultado de funil para aprender, não apenas visualização.'
    when 'horizonte' then 'Expansão deve partir de domínio operacional e unit economics comprovados. Defina demanda, capacidade, investimento, prazo, risco e critério de parada.'
    else 'Todo trabalho deve estar ligado a um problema de negócio, baseline, meta, ação, evidência, resultado medido, decisão e aprendizado validado.'
  end,
  array['comando-crescimento-esf', 'contrato-operacional', 'crescimento-real'],
  jsonb_build_object(
    'operating_system', 'Comando de Crescimento ESF',
    'contract_version', 1,
    'agent_slug', agent.slug,
    'required_fields', jsonb_build_array(
      'business_problem', 'baseline', 'target', 'action', 'evidence',
      'measured_result', 'decision', 'learning'
    )
  ),
  'historico_operacional', 'Comando de Crescimento ESF', 'Leonardo',
  current_date + 365, array[agent.slug, 'admin-total'], 'approved', 100
from public.agents_registry agent
where agent.is_active
  and agent.slug in (
    'admin-total', 'estrategista', 'tracao', 'comercial', 'bastia', 'operacao',
    'cifra', 'plataforma', 'espia', 'concorrencia', 'pauta', 'reels', 'horizonte'
  )
on conflict (agent_id, slug) do update
set content = excluded.content,
    tags = excluded.tags,
    metadata = excluded.metadata,
    valid_until = excluded.valid_until,
    allowed_audiences = excluded.allowed_audiences,
    approval_status = excluded.approval_status,
    priority = excluded.priority,
    updated_at = now();

do $cron$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id from cron.job where jobname = 'growth-command-scorecard-hourly';
  if v_job_id is not null then perform cron.unschedule(v_job_id); end if;
  perform cron.schedule(
    'growth-command-scorecard-hourly',
    '11 * * * *',
    'select public.growth_refresh_scorecard();'
  );
end;
$cron$;

-- Leonardo activates the initial portfolio after all gates are installed.
do $activate$
declare
  v_experiment record;
  v_leonardo uuid;
begin
  select id into v_leonardo from public.agents_registry where slug = 'admin-total' and is_active limit 1;
  for v_experiment in
    select id from public.growth_experiments
    where experiment_key in (
      'pele-conversion-recovery-2026-09',
      'prime-churn-below-six-2026-09',
      'attribution-media-to-enrollment-2026-09',
      'salto-leadership-baseline-2026-09'
    ) and status = 'planned'
    order by created_at
  loop
    perform public.growth_start_experiment(v_experiment.id, v_leonardo);
  end loop;
end;
$activate$;
