-- Make collaboration explicit on each growth mission and expose both target
-- attainment and progress made since the operating-system baseline.

create or replace view public.growth_command_scorecard
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
    when objective.status = 'achieved' then 100
    when objective.current_value is null or objective.baseline_value is null then null
    when objective.target_value = objective.baseline_value then 0
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
  objective.updated_at,
  objective.current_value - objective.baseline_value as change_from_baseline,
  case
    when objective.current_value is null then null
    when objective.direction = 'increase' and objective.target_value > 0
      then round(greatest(0, least(100, objective.current_value * 100 / objective.target_value)), 1)
    when objective.direction = 'decrease' and objective.current_value <= objective.target_value then 100
    when objective.direction = 'decrease' and objective.current_value > 0
      then round(greatest(0, least(100, objective.target_value * 100 / objective.current_value)), 1)
    else null
  end as target_attainment_pct,
  case
    when objective.status = 'achieved' then 100
    when objective.current_value is null or objective.baseline_value is null then null
    when objective.target_value = objective.baseline_value then 0
    when objective.direction = 'increase' then round(greatest(0, least(100,
      (objective.current_value - objective.baseline_value) * 100 /
      nullif(objective.target_value - objective.baseline_value, 0)
    )), 1)
    else round(greatest(0, least(100,
      (objective.baseline_value - objective.current_value) * 100 /
      nullif(objective.baseline_value - objective.target_value, 0)
    )), 1)
  end as progress_from_baseline_pct
from public.growth_objectives objective
join public.agents_registry agent on agent.id = objective.owner_agent_id;

grant select on public.growth_command_scorecard to authenticated, service_role;

insert into public.agent_mission_subscriptions(tenant_id, task_id, agent_id, reason)
select experiment.tenant_id, owner_assignment.task_id, assignment.agent_id,
  case
    when assignment.responsibility = 'owner' then 'owner'
    when agent.slug = 'admin-total' then 'orchestrator'
    else 'mention'
  end
from public.growth_experiment_agents assignment
join public.growth_experiments experiment on experiment.id = assignment.experiment_id
join public.growth_experiment_agents owner_assignment
  on owner_assignment.experiment_id = experiment.id
  and owner_assignment.responsibility = 'owner'
  and owner_assignment.task_id is not null
join public.agents_registry agent on agent.id = assignment.agent_id
on conflict (task_id, agent_id) do nothing;

with teams as (
  select
    experiment.id experiment_id,
    owner_assignment.task_id,
    array_agg(agent.slug order by assignment.responsibility, agent.slug)
      filter (where assignment.responsibility <> 'owner') as supporting_slugs,
    string_agg(
      '- ' || agent.display_name || ' (' || assignment.responsibility || '): ' || assignment.deliverable,
      E'\n' order by assignment.responsibility, agent.slug
    ) as team_contract
  from public.growth_experiments experiment
  join public.growth_experiment_agents owner_assignment
    on owner_assignment.experiment_id = experiment.id
    and owner_assignment.responsibility = 'owner'
    and owner_assignment.task_id is not null
  join public.growth_experiment_agents assignment on assignment.experiment_id = experiment.id
  join public.agents_registry agent on agent.id = assignment.agent_id
  group by experiment.id, owner_assignment.task_id
)
update public.agent_mission_tasks task
set description = case when task.description like '%EQUIPE INTEGRADA%'
      then task.description
      else left(task.description || E'\n\nEQUIPE INTEGRADA\n' || teams.team_contract ||
        E'\n\nO agente proprietário consolida as contribuições. Agentes de apoio não criam relatórios paralelos: entregam sua parte no mesmo experimento e usam a mesma métrica e evidência.', 12000)
      end,
    metadata = task.metadata || jsonb_build_object(
      'supporting_agent_slugs', coalesce(to_jsonb(teams.supporting_slugs), '[]'::jsonb),
      'team_coordination', 'single_experiment_shared_evidence',
      'team_connected_at', now()
    ),
    updated_at = now()
from teams
where task.id = teams.task_id;

insert into public.agent_mission_comments(
  tenant_id, task_id, author_agent_id, body, mentions, metadata
)
select
  experiment.tenant_id,
  owner_assignment.task_id,
  leonardo.id,
  'Leonardo: esta é uma missão integrada do Comando de Crescimento ESF. Cada agente contribui apenas com seu entregável no mesmo experimento. A conclusão exige baseline, resultado medido, evidência e decisão de escalar, iterar ou parar.',
  coalesce(array_agg(agent.slug order by agent.slug)
    filter (where agent.slug <> 'admin-total'), '{}'::text[]),
  jsonb_build_object(
    'source', 'comando-crescimento-esf-v1',
    'growth_experiment_id', experiment.id,
    'coordination_type', 'integrated_growth_team'
  )
from public.growth_experiments experiment
join public.growth_experiment_agents owner_assignment
  on owner_assignment.experiment_id = experiment.id
  and owner_assignment.responsibility = 'owner'
  and owner_assignment.task_id is not null
join public.growth_experiment_agents assignment on assignment.experiment_id = experiment.id
join public.agents_registry agent on agent.id = assignment.agent_id
cross join lateral (
  select id from public.agents_registry where slug = 'admin-total' and is_active limit 1
) leonardo
where not exists (
  select 1 from public.agent_mission_comments existing
  where existing.task_id = owner_assignment.task_id
    and existing.metadata->>'coordination_type' = 'integrated_growth_team'
)
group by experiment.id, experiment.tenant_id, owner_assignment.task_id, leonardo.id;

comment on view public.growth_command_scorecard is
  'Comando de Crescimento ESF scorecard with target attainment and progress since baseline.';
