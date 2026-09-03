-- Give the launch portfolio precedence and finish the user-visible product rename.
update public.agent_mission_tasks task
set priority = 'critical',
    metadata = task.metadata || jsonb_build_object(
      'operating_system', 'Comando de Crescimento ESF',
      'launch_cycle', true,
      'growth_execution_status', 'ready_for_agent'
    ),
    updated_at = now()
from public.growth_experiment_agents assignment
join public.growth_experiments experiment on experiment.id = assignment.experiment_id
where assignment.task_id = task.id
  and assignment.agent_id = experiment.owner_agent_id
  and experiment.status = 'running';

-- `mission_control` remains the compatibility channel identifier. Its visible
-- session title and dispatch instruction now use the product's new name.
do $rename_dispatch$
declare
  v_definition text;
begin
  select pg_get_functiondef(
    'public.agent_mission_dispatch_cycle_unlocked(integer)'::regprocedure
  ) into v_definition;

  if position('Mission Control · ' in v_definition) = 0
     or position('[MISSION CONTROL ESF — EXECUÇÃO REAL]' in v_definition) = 0 then
    raise exception 'Expected legacy dispatch labels were not found';
  end if;

  v_definition := replace(
    v_definition,
    'Mission Control · ',
    'Comando de Crescimento ESF · '
  );
  v_definition := replace(
    v_definition,
    '[MISSION CONTROL ESF — EXECUÇÃO REAL]',
    '[COMANDO DE CRESCIMENTO ESF — EXECUÇÃO REAL]'
  );

  execute v_definition;
end;
$rename_dispatch$;

update public.agents_sessions session
set title = 'Comando de Crescimento ESF · ' || agent.display_name,
    updated_at = now()
from public.agents_registry agent
where agent.id = session.agent_id
  and session.channel = 'mission_control'
  and session.status = 'active'
  and session.title is distinct from
      'Comando de Crescimento ESF · ' || agent.display_name;

insert into public.agent_mission_events(
  tenant_id, event_type, actor_agent_id, title, detail, payload
)
select
  '00000000-0000-0000-0000-000000000001'::uuid,
  'growth_command_launch_ready',
  leonardo.id,
  'Comando de Crescimento ESF pronto para execução',
  'As quatro missões iniciais receberam prioridade crítica, equipe integrada e contrato de evidência.',
  jsonb_build_object(
    'operating_system', 'Comando de Crescimento ESF',
    'running_experiments', 4,
    'max_active_experiments', 5,
    'legacy_channel_identifier_retained', 'mission_control'
  )
from public.agents_registry leonardo
where leonardo.slug = 'admin-total'
  and not exists (
    select 1
    from public.agent_mission_events event
    where event.event_type = 'growth_command_launch_ready'
  );
