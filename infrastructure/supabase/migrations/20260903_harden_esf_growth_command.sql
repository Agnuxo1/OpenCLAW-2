-- Growth mutations run only through trusted agent and scheduler infrastructure.
revoke execute on function public.growth_refresh_scorecard()
  from public, anon, authenticated;
revoke execute on function public.growth_record_observation(
  uuid, numeric, date, text, jsonb, uuid, uuid, text
) from public, anon, authenticated;
revoke execute on function public.growth_conclude_experiment(
  uuid, numeric, text, text, jsonb, uuid
) from public, anon, authenticated;
revoke execute on function public.growth_validate_learning(
  uuid, uuid, boolean, text
) from public, anon, authenticated;
revoke execute on function public.growth_start_experiment(uuid, uuid)
  from public, anon, authenticated;

grant execute on function public.growth_refresh_scorecard()
  to service_role;
grant execute on function public.growth_record_observation(
  uuid, numeric, date, text, jsonb, uuid, uuid, text
) to service_role;
grant execute on function public.growth_conclude_experiment(
  uuid, numeric, text, text, jsonb, uuid
) to service_role;
grant execute on function public.growth_validate_learning(
  uuid, uuid, boolean, text
) to service_role;
grant execute on function public.growth_start_experiment(uuid, uuid)
  to service_role;

-- This historical backup was the only ERROR-level public-schema advisor finding.
-- It remains inaccessible through the API while retaining privileged recovery use.
alter table if exists public._backup_handoff_task_autoclose_02set2026
  enable row level security;
