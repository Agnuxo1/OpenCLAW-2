-- Cover relationship lookups used by the command dashboard and audit trail.
create index if not exists growth_experiment_agents_task_idx
  on public.growth_experiment_agents(task_id);
create index if not exists growth_experiments_objective_idx
  on public.growth_experiments(objective_id);
create index if not exists growth_experiments_owner_idx
  on public.growth_experiments(owner_agent_id);
create index if not exists growth_learnings_objective_idx
  on public.growth_learnings(objective_id);
create index if not exists growth_learnings_validator_idx
  on public.growth_learnings(validated_by_agent_id);
create index if not exists growth_metric_observations_experiment_idx
  on public.growth_metric_observations(experiment_id);
create index if not exists growth_metric_observations_recorder_idx
  on public.growth_metric_observations(recorded_by_agent_id);
create index if not exists growth_objectives_owner_idx
  on public.growth_objectives(owner_agent_id);
