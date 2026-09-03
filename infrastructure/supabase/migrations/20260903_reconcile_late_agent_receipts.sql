-- A runner can finish after the proxy's 150-second transport timeout. Reconcile
-- those attempts only when the task contains a newer structured receipt.
create or replace function public.agent_mission_reconcile_late_receipts(
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_reconciled integer := 0;
begin
  with candidates as (
    select attempt.id,
      (task.metadata #>> '{execution_receipt,verified_at}')::timestamptz as verified_at
    from public.agent_mission_dispatch_attempts attempt
    join public.agent_mission_tasks task on task.id = attempt.task_id
    where attempt.status = 'failed'
      and attempt.http_status = 504
      and attempt.dispatched_at > now() - interval '24 hours'
      and task.status in ('done', 'review')
      and task.metadata #>> '{execution_receipt,verified_at}' is not null
      and (task.metadata #>> '{execution_receipt,verified_at}')::timestamptz
          >= attempt.dispatched_at
    order by attempt.dispatched_at
    limit greatest(1, least(coalesce(p_limit, 100), 500))
  ), reconciled as (
    update public.agent_mission_dispatch_attempts attempt
    set status = 'succeeded',
        checked_at = now(),
        completed_at = candidates.verified_at,
        metadata = attempt.metadata || jsonb_build_object(
          'late_receipt_reconciled', true,
          'late_receipt_reconciled_at', now(),
          'transport_warning', coalesce(attempt.error_message, 'HTTP 504')
        ),
        error_message = null
    from candidates
    where attempt.id = candidates.id
    returning attempt.id
  )
  select count(*) into v_reconciled from reconciled;

  return jsonb_build_object('reconciled', v_reconciled, 'at', now());
end;
$function$;

revoke execute on function public.agent_mission_reconcile_late_receipts(integer)
  from public, anon, authenticated;
grant execute on function public.agent_mission_reconcile_late_receipts(integer)
  to service_role;

do $cron$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id
  from cron.job
  where jobname = 'agent-mission-response-check-1min';

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;

  perform cron.schedule(
    'agent-mission-response-check-1min',
    '1-59/2 * * * *',
    'select public.agent_mission_validate_dispatch_responses(100); select public.agent_mission_reconcile_late_receipts(100);'
  );
end;
$cron$;

select public.agent_mission_reconcile_late_receipts(100);
