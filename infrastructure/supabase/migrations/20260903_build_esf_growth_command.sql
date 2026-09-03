-- Comando de Crescimento ESF
-- Closed-loop operating system: objective -> experiment -> task -> evidence ->
-- decision -> validated learning shared only with participating agents.

create table public.growth_system_config (
  singleton boolean primary key default true check (singleton),
  product_name text not null,
  positioning text not null,
  geography text not null,
  north_star text not null,
  operating_principles jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.growth_system_config(
  singleton, product_name, positioning, geography, north_star, operating_principles
) values (
  true,
  'Comando de Crescimento ESF',
  'Sistema operacional dos agentes para crescimento real e liderança local da Espaço Fitness',
  'Salto-SP',
  'Crescimento líquido sustentável da base ativa, com aquisição eficiente, conversão, retenção e margem',
  jsonb_build_object(
    'max_active_experiments', 5,
    'evidence_required', true,
    'baseline_required', true,
    'owner_required', true,
    'external_action_requires_human_approval', true,
    'learning_requires_leonardo_validation', true,
    'no_vanity_metrics', true
  )
);

create table public.growth_objectives (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  objective_key text not null,
  title text not null,
  description text not null,
  pillar text not null check (pillar in (
    'acquisition', 'conversion', 'retention', 'revenue', 'leadership', 'infrastructure'
  )),
  metric_key text not null,
  metric_unit text not null,
  direction text not null check (direction in ('increase', 'decrease')),
  baseline_value numeric,
  current_value numeric,
  target_value numeric not null,
  baseline_at timestamptz,
  target_at timestamptz not null,
  owner_agent_id uuid not null references public.agents_registry(id),
  status text not null default 'active' check (status in ('draft', 'active', 'achieved', 'paused', 'cancelled')),
  data_source text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, objective_key)
);

create table public.growth_experiments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  objective_id uuid not null references public.growth_objectives(id),
  experiment_key text not null,
  title text not null,
  hypothesis text not null,
  expected_outcome text not null,
  unit_scope text[] not null default array['Salto']::text[],
  audience text,
  owner_agent_id uuid not null references public.agents_registry(id),
  status text not null default 'planned' check (status in (
    'draft', 'planned', 'running', 'paused', 'won', 'lost', 'inconclusive', 'cancelled'
  )),
  stage text not null default 'design' check (stage in ('discover', 'design', 'execute', 'measure', 'learn')),
  metric_key text not null,
  baseline_value numeric,
  target_value numeric not null,
  result_value numeric,
  guardrails jsonb not null default '{}'::jsonb,
  budget_cap numeric not null default 0 check (budget_cap >= 0),
  starts_at timestamptz,
  ends_at timestamptz not null,
  result_summary text,
  decision text check (decision is null or decision in ('scale', 'iterate', 'stop')),
  evidence jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, experiment_key)
);

create table public.growth_experiment_agents (
  experiment_id uuid not null references public.growth_experiments(id) on delete cascade,
  agent_id uuid not null references public.agents_registry(id),
  responsibility text not null check (responsibility in ('owner', 'strategy', 'execution', 'measurement', 'review')),
  deliverable text not null,
  task_id uuid references public.agent_mission_tasks(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (experiment_id, agent_id)
);

create table public.growth_metric_observations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  objective_id uuid not null references public.growth_objectives(id) on delete cascade,
  experiment_id uuid references public.growth_experiments(id) on delete cascade,
  metric_key text not null,
  metric_value numeric not null,
  metric_unit text not null,
  unit_name text,
  observed_on date not null,
  source_name text not null,
  evidence jsonb not null default '{}'::jsonb,
  recorded_by_agent_id uuid references public.agents_registry(id),
  created_at timestamptz not null default now()
);

create table public.growth_learnings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  experiment_id uuid not null references public.growth_experiments(id),
  objective_id uuid not null references public.growth_objectives(id),
  title text not null,
  learning text not null,
  evidence jsonb not null,
  status text not null default 'candidate' check (status in ('candidate', 'validated', 'rejected')),
  applicable_agent_slugs text[] not null default '{}'::text[],
  validated_by_agent_id uuid references public.agents_registry(id),
  validated_at timestamptz,
  created_at timestamptz not null default now(),
  unique (experiment_id)
);

create index growth_objectives_status_idx on public.growth_objectives(tenant_id, status, pillar);
create index growth_experiments_portfolio_idx on public.growth_experiments(tenant_id, status, ends_at);
create index growth_experiment_agents_agent_idx on public.growth_experiment_agents(agent_id, experiment_id);
create index growth_metric_observations_lookup_idx on public.growth_metric_observations(objective_id, observed_on desc);
create index growth_learnings_status_idx on public.growth_learnings(tenant_id, status, created_at desc);

alter table public.growth_system_config enable row level security;
alter table public.growth_objectives enable row level security;
alter table public.growth_experiments enable row level security;
alter table public.growth_experiment_agents enable row level security;
alter table public.growth_metric_observations enable row level security;
alter table public.growth_learnings enable row level security;

create policy growth_config_read on public.growth_system_config for select to authenticated using (true);
create policy growth_objectives_read on public.growth_objectives for select to authenticated
  using (tenant_id = (select public.get_tenant_id()));
create policy growth_experiments_read on public.growth_experiments for select to authenticated
  using (tenant_id = (select public.get_tenant_id()));
create policy growth_experiment_agents_read on public.growth_experiment_agents for select to authenticated
  using (exists (
    select 1 from public.growth_experiments experiment
    where experiment.id = experiment_id
      and experiment.tenant_id = (select public.get_tenant_id())
  ));
create policy growth_observations_read on public.growth_metric_observations for select to authenticated
  using (tenant_id = (select public.get_tenant_id()));
create policy growth_learnings_read on public.growth_learnings for select to authenticated
  using (tenant_id = (select public.get_tenant_id()));

revoke all on public.growth_system_config, public.growth_objectives, public.growth_experiments,
  public.growth_experiment_agents, public.growth_metric_observations, public.growth_learnings
  from anon, authenticated;
grant select on public.growth_system_config, public.growth_objectives, public.growth_experiments,
  public.growth_experiment_agents, public.growth_metric_observations, public.growth_learnings
  to authenticated;
grant all on public.growth_system_config, public.growth_objectives, public.growth_experiments,
  public.growth_experiment_agents, public.growth_metric_observations, public.growth_learnings
  to service_role;

create or replace function public.growth_set_updated_at()
returns trigger language plpgsql set search_path to 'public', 'pg_temp' as $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

create trigger growth_objectives_updated_at before update on public.growth_objectives
for each row execute function public.growth_set_updated_at();
create trigger growth_experiments_updated_at before update on public.growth_experiments
for each row execute function public.growth_set_updated_at();

create or replace function public.growth_refresh_scorecard()
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_updated integer := 0;
begin
  with latest as (
    select distinct on (id_branch)
      id_branch, dia, novas_mes_ate_dia, evasao_30d_pct, base_ativa, mrr
    from public.metricas_diarias
    order by id_branch, dia desc, capturado_at desc
  ), refreshed as (
    update public.growth_objectives objective
    set current_value = case objective.metric_key
          when 'monthly_enrollments' then latest.novas_mes_ate_dia
          when 'churn_30d_pct' then latest.evasao_30d_pct
          when 'active_members' then latest.base_ativa
          when 'mrr_brl' then latest.mrr
          else objective.current_value
        end,
        baseline_value = coalesce(objective.baseline_value, case objective.metric_key
          when 'monthly_enrollments' then latest.novas_mes_ate_dia
          when 'churn_30d_pct' then latest.evasao_30d_pct
          when 'active_members' then latest.base_ativa
          when 'mrr_brl' then latest.mrr
          else null
        end),
        baseline_at = coalesce(objective.baseline_at, latest.dia::timestamptz),
        metadata = objective.metadata || jsonb_build_object(
          'source_observed_on', latest.dia,
          'refreshed_at', now()
        )
    from latest
    where (objective.metadata->>'id_branch')::integer = latest.id_branch
      and objective.status in ('active', 'achieved')
    returning objective.id
  )
  select count(*) into v_updated from refreshed;

  update public.growth_objectives objective
  set current_value = least(100, (
        select count(distinct data.date)::numeric * 100 / 7
        from public.meta_ads_daily_data data
        where data.date >= current_date - 6
      )),
      metadata = objective.metadata || jsonb_build_object('refreshed_at', now(), 'window_days', 7)
  where objective.metric_key = 'meta_attribution_coverage_pct'
    and objective.status in ('active', 'achieved');

  with latest_observation as (
    select distinct on (metric.objective_id)
      metric.objective_id, metric.id, metric.metric_value, metric.observed_on
    from public.growth_metric_observations metric
    order by metric.objective_id, metric.observed_on desc, metric.created_at desc
  )
  update public.growth_objectives objective
  set current_value = observation.metric_value,
      metadata = objective.metadata || jsonb_build_object(
        'last_observation_id', observation.id,
        'source_observed_on', observation.observed_on,
        'refreshed_at', now()
      )
  from latest_observation observation
  where observation.objective_id = objective.id
    and objective.metric_key not in (
    'monthly_enrollments', 'churn_30d_pct', 'active_members', 'mrr_brl',
    'meta_attribution_coverage_pct'
  );

  update public.growth_objectives
  set status = case
    when direction = 'increase' and current_value >= target_value then 'achieved'
    when direction = 'decrease' and current_value <= target_value then 'achieved'
    when status = 'achieved' then 'active'
    else status end
  where status in ('active', 'achieved') and current_value is not null;

  return jsonb_build_object('updated_from_operations', v_updated, 'refreshed_at', now());
end;
$function$;

create or replace function public.growth_record_observation(
  p_objective_id uuid,
  p_metric_value numeric,
  p_observed_on date,
  p_source_name text,
  p_evidence jsonb,
  p_agent_id uuid default null,
  p_experiment_id uuid default null,
  p_unit_name text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_objective public.growth_objectives%rowtype;
  v_id uuid;
begin
  select * into v_objective from public.growth_objectives where id = p_objective_id;
  if v_objective.id is null then raise exception 'Growth objective not found'; end if;
  if nullif(btrim(p_source_name), '') is null then raise exception 'Observation source is required'; end if;
  if coalesce(p_evidence, '{}'::jsonb) = '{}'::jsonb then raise exception 'Observation evidence is required'; end if;
  if p_experiment_id is not null and not exists (
    select 1 from public.growth_experiments
    where id = p_experiment_id and objective_id = p_objective_id
  ) then raise exception 'Experiment does not belong to objective'; end if;

  insert into public.growth_metric_observations(
    tenant_id, objective_id, experiment_id, metric_key, metric_value, metric_unit,
    unit_name, observed_on, source_name, evidence, recorded_by_agent_id
  ) values (
    v_objective.tenant_id, v_objective.id, p_experiment_id, v_objective.metric_key,
    p_metric_value, v_objective.metric_unit, p_unit_name, p_observed_on,
    btrim(p_source_name), p_evidence, p_agent_id
  ) returning id into v_id;

  update public.growth_objectives
  set current_value = p_metric_value,
      metadata = metadata || jsonb_build_object(
        'last_observation_id', v_id,
        'source_observed_on', p_observed_on
      )
  where id = p_objective_id;

  return v_id;
end;
$function$;

create or replace function public.growth_conclude_experiment(
  p_experiment_id uuid,
  p_result_value numeric,
  p_result_summary text,
  p_decision text,
  p_evidence jsonb,
  p_agent_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_experiment public.growth_experiments%rowtype;
  v_objective public.growth_objectives%rowtype;
  v_status text;
  v_learning_id uuid;
begin
  if p_decision not in ('scale', 'iterate', 'stop') then raise exception 'Decision must be scale, iterate or stop'; end if;
  if length(btrim(coalesce(p_result_summary, ''))) < 40 then raise exception 'Result summary must explain the measured outcome'; end if;
  if jsonb_typeof(coalesce(p_evidence, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_evidence, '[]'::jsonb)) = 0 then
    raise exception 'At least one evidence item is required';
  end if;

  select * into v_experiment from public.growth_experiments where id = p_experiment_id for update;
  if v_experiment.id is null then raise exception 'Growth experiment not found'; end if;
  if v_experiment.status not in ('planned', 'running', 'paused') then raise exception 'Experiment is not open'; end if;
  select * into v_objective from public.growth_objectives where id = v_experiment.objective_id;

  v_status := case
    when v_objective.direction = 'increase' and p_result_value >= v_experiment.target_value then 'won'
    when v_objective.direction = 'decrease' and p_result_value <= v_experiment.target_value then 'won'
    when p_decision = 'stop' then 'lost'
    else 'inconclusive' end;

  perform public.growth_record_observation(
    v_objective.id, p_result_value, current_date, 'experiment_result',
    jsonb_build_object('items', p_evidence, 'summary', p_result_summary),
    p_agent_id, v_experiment.id, array_to_string(v_experiment.unit_scope, ', ')
  );

  update public.growth_experiments
  set status = v_status, stage = 'learn', result_value = p_result_value,
      result_summary = btrim(p_result_summary), decision = p_decision,
      evidence = p_evidence, updated_at = now()
  where id = v_experiment.id;

  insert into public.growth_learnings(
    tenant_id, experiment_id, objective_id, title, learning, evidence,
    applicable_agent_slugs
  )
  select
    v_experiment.tenant_id, v_experiment.id, v_objective.id,
    'Aprendizado: ' || v_experiment.title,
    p_result_summary, p_evidence,
    coalesce(array_agg(distinct agent.slug) filter (where agent.slug is not null), '{}'::text[])
  from public.growth_experiment_agents assignment
  join public.agents_registry agent on agent.id = assignment.agent_id
  where assignment.experiment_id = v_experiment.id
  returning id into v_learning_id;

  update public.agent_mission_tasks task
  set status = 'review',
      metadata = task.metadata || jsonb_build_object(
        'growth_result_value', p_result_value,
        'growth_decision', p_decision,
        'growth_learning_id', v_learning_id,
        'growth_result_status', v_status,
        'leonardo_validation_required', true
      ),
      updated_at = now()
  where task.metadata->>'growth_experiment_id' = v_experiment.id::text
    and task.status not in ('done', 'cancelled');

  return jsonb_build_object(
    'experiment_id', v_experiment.id, 'status', v_status,
    'decision', p_decision, 'learning_id', v_learning_id,
    'requires_leonardo_validation', true
  );
end;
$function$;

create or replace function public.growth_validate_learning(
  p_learning_id uuid,
  p_reviewer_agent_id uuid,
  p_approve boolean,
  p_review_note text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_learning public.growth_learnings%rowtype;
  v_reviewer_slug text;
  v_note_count integer := 0;
begin
  select slug into v_reviewer_slug from public.agents_registry where id = p_reviewer_agent_id;
  if v_reviewer_slug <> 'admin-total' then raise exception 'Only Leonardo can validate growth learning'; end if;
  if length(btrim(coalesce(p_review_note, ''))) < 12 then raise exception 'Review note is required'; end if;
  select * into v_learning from public.growth_learnings where id = p_learning_id for update;
  if v_learning.id is null or v_learning.status <> 'candidate' then raise exception 'Candidate learning not found'; end if;

  update public.growth_learnings
  set status = case when p_approve then 'validated' else 'rejected' end,
      validated_by_agent_id = p_reviewer_agent_id,
      validated_at = now(),
      learning = learning || E'\n\nRevisão Leonardo: ' || btrim(p_review_note)
  where id = v_learning.id;

  if p_approve then
    insert into public.agent_notes(
      agent_id, title, slug, content, tags, metadata, collection, source_name,
      responsible, valid_until, allowed_audiences, approval_status, priority
    )
    select
      agent.id, v_learning.title,
      'growth-' || replace(v_learning.id::text, '-', ''),
      v_learning.learning || E'\n\nRevisão Leonardo: ' || btrim(p_review_note),
      array['crescimento', 'experimento-validado', 'comando-crescimento-esf'],
      jsonb_build_object(
        'growth_learning_id', v_learning.id,
        'growth_experiment_id', v_learning.experiment_id,
        'evidence', v_learning.evidence,
        'validated_by', 'admin-total'
      ),
      'historico_operacional', 'Comando de Crescimento ESF',
      'Leonardo', current_date + 180,
      v_learning.applicable_agent_slugs || array['admin-total'],
      'approved', 90
    from public.agents_registry agent
    where agent.slug = any(v_learning.applicable_agent_slugs || array['admin-total'])
    on conflict (agent_id, slug) do update
    set content = excluded.content, metadata = excluded.metadata,
        allowed_audiences = excluded.allowed_audiences,
        approval_status = 'approved', updated_at = now();
    get diagnostics v_note_count = row_count;
  end if;

  update public.agent_mission_tasks task
  set status = case when p_approve then 'done' else 'blocked' end,
      completed_at = case when p_approve then now() else task.completed_at end,
      metadata = task.metadata || jsonb_build_object(
        'growth_learning_validation', case when p_approve then 'validated' else 'rejected' end,
        'growth_review_note', p_review_note
      ),
      updated_at = now()
  where task.metadata->>'growth_learning_id' = v_learning.id::text;

  return jsonb_build_object(
    'learning_id', v_learning.id,
    'status', case when p_approve then 'validated' else 'rejected' end,
    'shared_memory_notes', v_note_count
  );
end;
$function$;

revoke all on function public.growth_refresh_scorecard() from public;
revoke all on function public.growth_record_observation(uuid,numeric,date,text,jsonb,uuid,uuid,text) from public;
revoke all on function public.growth_conclude_experiment(uuid,numeric,text,text,jsonb,uuid) from public;
revoke all on function public.growth_validate_learning(uuid,uuid,boolean,text) from public;
grant execute on function public.growth_refresh_scorecard() to service_role;
grant execute on function public.growth_record_observation(uuid,numeric,date,text,jsonb,uuid,uuid,text) to service_role;
grant execute on function public.growth_conclude_experiment(uuid,numeric,text,text,jsonb,uuid) to service_role;
grant execute on function public.growth_validate_learning(uuid,uuid,boolean,text) to service_role;

create view public.growth_command_scorecard
with (security_invoker = true)
as
select
  objective.id,
  objective.tenant_id,
  objective.objective_key,
  objective.title,
  objective.pillar,
  objective.metric_key,
  objective.metric_unit,
  objective.direction,
  objective.baseline_value,
  objective.current_value,
  objective.target_value,
  objective.target_at,
  objective.status,
  agent.slug as owner_slug,
  agent.display_name as owner_name,
  case
    when objective.current_value is null or objective.baseline_value is null then null
    when objective.target_value = objective.baseline_value then
      case when objective.status = 'achieved' then 100 else 0 end
    when objective.direction = 'increase' then round(greatest(0, least(100,
      (objective.current_value - objective.baseline_value) * 100 /
      nullif(objective.target_value - objective.baseline_value, 0)
    )), 1)
    else round(greatest(0, least(100,
      (objective.baseline_value - objective.current_value) * 100 /
      nullif(objective.baseline_value - objective.target_value, 0)
    )), 1)
  end as progress_pct,
  objective.data_source,
  objective.metadata,
  objective.updated_at
from public.growth_objectives objective
join public.agents_registry agent on agent.id = objective.owner_agent_id;

create view public.growth_command_experiment_board
with (security_invoker = true)
as
select
  experiment.id,
  experiment.tenant_id,
  experiment.experiment_key,
  experiment.title,
  objective.title as objective_title,
  objective.pillar,
  experiment.hypothesis,
  experiment.expected_outcome,
  experiment.unit_scope,
  experiment.status,
  experiment.stage,
  experiment.baseline_value,
  experiment.target_value,
  experiment.result_value,
  experiment.ends_at,
  experiment.decision,
  owner.slug as owner_slug,
  owner.display_name as owner_name,
  coalesce(jsonb_agg(jsonb_build_object(
    'agent', participant.slug,
    'name', participant.display_name,
    'responsibility', assignment.responsibility,
    'deliverable', assignment.deliverable,
    'task_id', assignment.task_id
  ) order by assignment.responsibility, participant.slug)
    filter (where participant.id is not null), '[]'::jsonb) as agent_team
from public.growth_experiments experiment
join public.growth_objectives objective on objective.id = experiment.objective_id
join public.agents_registry owner on owner.id = experiment.owner_agent_id
left join public.growth_experiment_agents assignment on assignment.experiment_id = experiment.id
left join public.agents_registry participant on participant.id = assignment.agent_id
group by experiment.id, objective.id, owner.id;

grant select on public.growth_command_scorecard, public.growth_command_experiment_board to authenticated, service_role;

-- Seed objectives from the latest operational facts and official unit goals.
with latest as (
  select distinct on (metric.id_branch) metric.*
  from public.metricas_diarias metric
  order by metric.id_branch, metric.dia desc, metric.capturado_at desc
), seed as (
  select
    latest.id_branch,
    unit.unidade,
    latest.dia,
    latest.novas_mes_ate_dia,
    latest.evasao_30d_pct,
    unit.meta_matriculas
  from latest join public.unidade_metas unit using(id_branch)
)
insert into public.growth_objectives(
  tenant_id, objective_key, title, description, pillar, metric_key, metric_unit,
  direction, baseline_value, current_value, target_value, baseline_at, target_at,
  owner_agent_id, status, data_source, metadata
)
select
  '00000000-0000-0000-0000-000000000001'::uuid,
  'matriculas-' || lower(seed.unidade) || '-2026-09',
  seed.unidade || ': atingir a meta de matrículas de setembro',
  'Crescer com atribuição verificável, conversão saudável e capacidade operacional protegida.',
  'conversion', 'monthly_enrollments', 'matrículas', 'increase',
  seed.novas_mes_ate_dia, seed.novas_mes_ate_dia, seed.meta_matriculas,
  seed.dia::timestamptz, '2026-09-30 23:59:59-03'::timestamptz,
  (select id from public.agents_registry where slug = 'comercial' limit 1),
  'active', 'metricas_diarias + unidade_metas',
  jsonb_build_object('id_branch', seed.id_branch, 'unit', seed.unidade, 'source_observed_on', seed.dia)
from seed
union all
select
  '00000000-0000-0000-0000-000000000001'::uuid,
  'evasao-' || lower(seed.unidade) || '-2026-09',
  seed.unidade || ': manter evasão de 30 dias abaixo de 6%',
  'Reduzir cancelamento sem desconto predatório, protegendo experiência, frequência e margem.',
  'retention', 'churn_30d_pct', '%', 'decrease',
  seed.evasao_30d_pct, seed.evasao_30d_pct, 5.99,
  seed.dia::timestamptz, '2026-09-30 23:59:59-03'::timestamptz,
  (select id from public.agents_registry where slug = 'bastia' limit 1),
  case when seed.evasao_30d_pct <= 5.99 then 'achieved' else 'active' end,
  'metricas_diarias',
  jsonb_build_object('id_branch', seed.id_branch, 'unit', seed.unidade, 'source_observed_on', seed.dia)
from seed;

insert into public.growth_objectives(
  tenant_id, objective_key, title, description, pillar, metric_key, metric_unit,
  direction, baseline_value, current_value, target_value, baseline_at, target_at,
  owner_agent_id, status, data_source, metadata
)
values
(
  '00000000-0000-0000-0000-000000000001'::uuid,
  'meta-attribution-coverage-2026-09',
  'Atribuição: conectar mídia, lead, visita e matrícula',
  'Eliminar decisões de aquisição sem rastreabilidade entre investimento e matrícula.',
  'infrastructure', 'meta_attribution_coverage_pct', '%', 'increase',
  0, 0, 95, now(), '2026-09-15 23:59:59-03'::timestamptz,
  (select id from public.agents_registry where slug = 'plataforma' limit 1),
  'active', 'meta_ads_daily_data + CRM + EVO',
  jsonb_build_object('source_rows_at_creation', 0, 'window_days', 7)
),
(
  '00000000-0000-0000-0000-000000000001'::uuid,
  'salto-leadership-measurement-2026-09',
  'Salto: estabelecer índice verificável de liderança local',
  'Medir presença local por procura, avaliações, share of voice, demanda e preferência, sem confundir alcance com liderança.',
  'leadership', 'leadership_measurement_coverage_pct', '%', 'increase',
  0, 0, 100, now(), '2026-09-09 23:59:59-03'::timestamptz,
  (select id from public.agents_registry where slug = 'espia' limit 1),
  'active', 'Google Business Profile + busca + social + concorrência + CRM',
  jsonb_build_object('city', 'Salto', 'measurement_components', jsonb_build_array(
    'share_of_search', 'review_velocity', 'local_share_of_voice', 'qualified_demand', 'brand_preference'
  ))
);

-- Four focused experiments; no department receives a task merely to stay busy.
insert into public.growth_experiments(
  tenant_id, objective_id, experiment_key, title, hypothesis, expected_outcome,
  unit_scope, audience, owner_agent_id, status, stage, metric_key,
  baseline_value, target_value, guardrails, budget_cap, starts_at, ends_at, metadata
)
values
(
  '00000000-0000-0000-0000-000000000001'::uuid,
  (select id from public.growth_objectives where objective_key = 'matriculas-pelé-2026-09'),
  'pele-conversion-recovery-2026-09',
  'Pelé: recuperar ritmo de matrículas com diagnóstico do funil',
  'Se identificarmos o maior vazamento entre lead, agendamento, comparecimento e matrícula e corrigirmos uma única etapa, a unidade retomará o ritmo necessário sem desconto predatório.',
  'Elevar matrículas acumuladas em direção a 40 no mês, com origem e conversão registradas.',
  array['Pelé'], 'Leads locais e visitantes da unidade Pelé',
  (select id from public.agents_registry where slug = 'comercial' limit 1),
  'planned', 'discover', 'monthly_enrollments', 1, 40,
  jsonb_build_object('no_unapproved_discount', true, 'protect_service_capacity', true, 'track_source', true),
  0, now(), '2026-09-16 23:59:59-03'::timestamptz,
  jsonb_build_object('decision_gate', 'funil medido e uma intervenção comparável executada')
),
(
  '00000000-0000-0000-0000-000000000001'::uuid,
  (select id from public.growth_objectives where objective_key = 'evasao-prime-2026-09'),
  'prime-churn-below-six-2026-09',
  'Prime: reduzir evasão de 6,24% para menos de 6%',
  'Se atuarmos nos sinais observáveis de queda de frequência e falha de onboarding antes do cancelamento, a evasão cairá sem reduzir preço.',
  'Evasão de 30 dias em até 5,99%, com frequência e margem protegidas.',
  array['Prime'], 'Alunos com queda de frequência ou falha de onboarding',
  (select id from public.agents_registry where slug = 'bastia' limit 1),
  'planned', 'design', 'churn_30d_pct', 6.24, 5.99,
  jsonb_build_object('no_mass_messaging', true, 'no_unapproved_discount', true, 'lgpd', true),
  0, now(), '2026-09-23 23:59:59-03'::timestamptz,
  jsonb_build_object('decision_gate', 'coorte comparável e evasão recalculada')
),
(
  '00000000-0000-0000-0000-000000000001'::uuid,
  (select id from public.growth_objectives where objective_key = 'meta-attribution-coverage-2026-09'),
  'attribution-media-to-enrollment-2026-09',
  'Dados: fechar atribuição de mídia até matrícula',
  'Se Meta Ads, CRM e EVO compartilharem identificadores e eventos consistentes, Tração e Cifra poderão decidir verba por matrícula em vez de alcance ou lead isolado.',
  'Cobertura de dados de ao menos 95% dos últimos sete dias e trilha lead→visita→matrícula auditável.',
  array['Salto', 'Prime', 'Pelé', 'Nações'], 'Todos os leads de mídia paga',
  (select id from public.agents_registry where slug = 'plataforma' limit 1),
  'planned', 'discover', 'meta_attribution_coverage_pct', 0, 95,
  jsonb_build_object('no_production_mutation_without_review', true, 'no_pii_in_logs', true),
  0, now(), '2026-09-15 23:59:59-03'::timestamptz,
  jsonb_build_object('decision_gate', 'sete dias de dados e reconciliação amostral')
),
(
  '00000000-0000-0000-0000-000000000001'::uuid,
  (select id from public.growth_objectives where objective_key = 'salto-leadership-measurement-2026-09'),
  'salto-leadership-baseline-2026-09',
  'Salto: construir a linha de base de liderança local',
  'Se medirmos procura, avaliações, share of voice, demanda qualificada e preferência com fontes repetíveis, Leonardo poderá priorizar ações que ampliem liderança real e não métricas de vaidade.',
  'Cobertura de 100% dos cinco componentes, com fonte, periodicidade e responsável definidos.',
  array['Salto'], 'Moradores e potenciais alunos de Salto',
  (select id from public.agents_registry where slug = 'espia' limit 1),
  'planned', 'discover', 'leadership_measurement_coverage_pct', 0, 100,
  jsonb_build_object('public_sources_only', true, 'no_claim_without_evidence', true),
  0, now(), '2026-09-09 23:59:59-03'::timestamptz,
  jsonb_build_object('decision_gate', 'cinco componentes reproduzíveis e baseline registrada')
);

insert into public.growth_experiment_agents(experiment_id, agent_id, responsibility, deliverable)
select experiment.id, agent.id, role.responsibility, role.deliverable
from (values
  ('pele-conversion-recovery-2026-09', 'comercial', 'owner', 'Funil Pelé medido e gargalo priorizado'),
  ('pele-conversion-recovery-2026-09', 'tracao', 'strategy', 'Intervenção de aquisição/conversão com hipótese e KPI'),
  ('pele-conversion-recovery-2026-09', 'bastia', 'review', 'Proteção da experiência e capacidade da unidade'),
  ('prime-churn-below-six-2026-09', 'bastia', 'owner', 'Coorte de risco, intervenção e evasão recalculada'),
  ('prime-churn-below-six-2026-09', 'operacao', 'execution', 'Aplicação operacional segura na Prime'),
  ('prime-churn-below-six-2026-09', 'comercial', 'measurement', 'Sinais de contato, retorno e renovação'),
  ('attribution-media-to-enrollment-2026-09', 'plataforma', 'owner', 'Pipeline de dados e reconciliação auditável'),
  ('attribution-media-to-enrollment-2026-09', 'tracao', 'review', 'UTMs, campanhas e eventos de mídia consistentes'),
  ('attribution-media-to-enrollment-2026-09', 'comercial', 'measurement', 'Eventos de lead, visita e matrícula definidos'),
  ('attribution-media-to-enrollment-2026-09', 'cifra', 'review', 'Regra financeira de CAC por matrícula'),
  ('salto-leadership-baseline-2026-09', 'espia', 'owner', 'Baseline dos cinco componentes de liderança local'),
  ('salto-leadership-baseline-2026-09', 'concorrencia', 'measurement', 'Share of voice e comparação pública verificável'),
  ('salto-leadership-baseline-2026-09', 'tracao', 'strategy', 'Demanda, procura e preferência traduzidas em ação'),
  ('salto-leadership-baseline-2026-09', 'plataforma', 'measurement', 'Fontes, periodicidade e atualização reproduzíveis'),
  ('salto-leadership-baseline-2026-09', 'admin-total', 'review', 'Validação executiva e decisão de portfólio')
) role(experiment_key, agent_slug, responsibility, deliverable)
join public.growth_experiments experiment on experiment.experiment_key = role.experiment_key
join public.agents_registry agent on agent.slug = role.agent_slug;

do $tasks$
declare
  v_experiment record;
  v_task_id uuid;
begin
  for v_experiment in
    select experiment.*, objective.title objective_title, objective.metric_unit,
      owner.display_name owner_name
    from public.growth_experiments experiment
    join public.growth_objectives objective on objective.id = experiment.objective_id
    join public.agents_registry owner on owner.id = experiment.owner_agent_id
    where experiment.status = 'planned'
  loop
    insert into public.agent_mission_tasks(
      tenant_id, title, description, status, priority, owner_agent_id,
      created_by_agent_id, due_at, tags, requires_approval, approval_status,
      external_actions_allowed, metadata
    ) values (
      v_experiment.tenant_id,
      left(v_experiment.title, 240),
      format(
        E'COMANDO DE CRESCIMENTO ESF\n\nObjetivo: %s\nHipótese: %s\nResultado esperado: %s\nBaseline: %s %s\nMeta: %s %s\nUnidade: %s\nPrazo: %s\n\nA entrega precisa conter diagnóstico com fonte, ação executada ou plano pronto para aprovação, evidência, valor medido, guardrails, decisão recomendada (escalar, iterar ou parar) e aprendizado. Métrica de vaidade não conclui a missão. Ações externas, gasto e contato com alunos exigem a aprovação aplicável.',
        v_experiment.objective_title, v_experiment.hypothesis,
        v_experiment.expected_outcome, coalesce(v_experiment.baseline_value::text, 'a medir'),
        v_experiment.metric_unit, v_experiment.target_value, v_experiment.metric_unit,
        array_to_string(v_experiment.unit_scope, ', '), v_experiment.ends_at::date
      ),
      'backlog', 'high', v_experiment.owner_agent_id,
      (select id from public.agents_registry where slug = 'admin-total' limit 1),
      v_experiment.ends_at, array['comando-crescimento-esf', 'growth-experiment', v_experiment.metric_key],
      false, 'approved', false,
      jsonb_build_object(
        'source', 'comando-crescimento-esf-v1',
        'mission_kind', 'growth_experiment_v1',
        'growth_experiment_id', v_experiment.id,
        'growth_objective_id', v_experiment.objective_id,
        'metric_key', v_experiment.metric_key,
        'baseline_value', v_experiment.baseline_value,
        'target_value', v_experiment.target_value,
        'guardrails', v_experiment.guardrails,
        'decision_gate', v_experiment.metadata->>'decision_gate',
        'evidence_required', true,
        'auto_practical_action_enabled', false,
        'leonardo_review_required', true
      )
    ) returning id into v_task_id;

    update public.growth_experiment_agents
    set task_id = v_task_id
    where experiment_id = v_experiment.id and agent_id = v_experiment.owner_agent_id;
  end loop;
end;
$tasks$;

-- Rename the operating layer and require recurring work to state its business outcome.
update public.agent_mission_recurring_schedules schedule
set metadata = schedule.metadata || jsonb_build_object(
      'source', 'comando-crescimento-esf-v1',
      'operating_system', 'Comando de Crescimento ESF',
      'outcome_contract_required', true,
      'required_output_fields', jsonb_build_array(
        'business_problem', 'baseline', 'target', 'action', 'evidence',
        'measured_result', 'decision', 'learning'
      )
    ),
    tags = case when 'comando-crescimento-esf' = any(schedule.tags)
      then schedule.tags else array_append(schedule.tags, 'comando-crescimento-esf') end,
    task_description = case when schedule.task_description like '%CONTRATO DE RESULTADO ESF%'
      then schedule.task_description
      else left(schedule.task_description || E'\n\nCONTRATO DE RESULTADO ESF: relacione a entrega a um problema de negócio, baseline, meta, ação, evidência, resultado medido, decisão e aprendizado. Relatório sem consequência operacional não conta como conclusão.', 12000)
      end,
    updated_at = now()
where schedule.enabled;

update public.agent_mission_recurring_schedules
set task_title = 'Conselho semanal do Comando de Crescimento ESF',
    task_description = E'Leonardo revisa o scorecard por unidade, limita o portfólio a cinco experimentos ativos, resolve dependências, encerra trabalho sem impacto e decide escalar, iterar ou parar com base em evidência.\n\nCONTRATO DE RESULTADO ESF: registrar variação dos KPIs, decisões, responsáveis, prazos, riscos e aprendizados validados.',
    metadata = metadata || jsonb_build_object(
      'deliverable', 'growth_portfolio_review',
      'max_active_experiments', 5,
      'scorecard_view', 'growth_command_scorecard',
      'portfolio_view', 'growth_command_experiment_board'
    ),
    updated_at = now()
where schedule_key = 'area-review:admin-total';

update public.agent_mission_tasks
set title = 'Conselho semanal do Comando de Crescimento ESF',
    metadata = metadata || jsonb_build_object(
      'source', 'comando-crescimento-esf-v1',
      'operating_system', 'Comando de Crescimento ESF'
    ),
    updated_at = now()
where status in ('backlog', 'blocked', 'in_progress', 'review')
  and title = 'Auditoria semanal dos agentes';

select public.growth_refresh_scorecard();

comment on table public.growth_objectives is 'Comando de Crescimento ESF: measurable business outcomes.';
comment on table public.growth_experiments is 'Comando de Crescimento ESF: bounded tests tied to objectives and evidence.';
comment on view public.growth_command_scorecard is 'Executive scorecard for the Comando de Crescimento ESF.';
