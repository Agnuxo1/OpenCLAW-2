-- Final audit pass: retire stale daily scans and classify specific overdue work
-- for owner revalidation without discarding it.

do $finalize$
declare
  v_batch uuid := gen_random_uuid();
begin
  insert into public.agent_mission_task_audit_snapshots(
    audit_batch_id, task_id, reason, previous_row
  )
  select v_batch, task.id, 'stale_daily_scan_retired', to_jsonb(task)
  from public.agent_mission_tasks task
  where task.status in ('backlog', 'blocked')
    and task.metadata->>'daily_learning' = 'true'
    and task.metadata->>'learning_date' < (current_date - 1)::text
    and not (task.metadata ? 'execution_receipt');

  update public.agent_mission_tasks task
  set status = 'cancelled',
      metadata = coalesce(task.metadata, '{}'::jsonb) || jsonb_build_object(
        'audit_cleanup_batch', v_batch,
        'audit_cleanup_reason', 'stale_daily_scan_retired',
        'superseded_at', now(),
        'history_preserved', true
      ),
      updated_at = now()
  where task.status in ('backlog', 'blocked')
    and task.metadata->>'daily_learning' = 'true'
    and task.metadata->>'learning_date' < (current_date - 1)::text
    and not (task.metadata ? 'execution_receipt');

  insert into public.agent_mission_task_audit_snapshots(
    audit_batch_id, task_id, reason, previous_row
  )
  select v_batch, task.id, 'specialized_github_learning_title', to_jsonb(task)
  from public.agent_mission_tasks task
  where task.status in ('backlog', 'blocked', 'in_progress', 'review')
    and task.metadata->>'daily_learning' = 'true'
    and task.metadata->>'github_growth_scan' = 'true'
    and task.metadata->>'mission_kind' is null;

  update public.agent_mission_tasks task
  set title = left(
        agent.display_name || ': radar GitHub aplicável ao domínio — ' ||
        coalesce(task.metadata->>'learning_date', current_date::text),
        240
      ),
      metadata = coalesce(task.metadata, '{}'::jsonb) || jsonb_build_object(
        'mission_kind', 'github_growth_learning_v2',
        'domain_focus', 'repositórios públicos aplicáveis a ' || agent.display_name,
        'specialized_at', now(),
        'specialization_audit_batch', v_batch
      ),
      updated_at = now()
  from public.agents_registry agent
  where agent.id = task.owner_agent_id
    and task.status in ('backlog', 'blocked', 'in_progress', 'review')
    and task.metadata->>'daily_learning' = 'true'
    and task.metadata->>'github_growth_scan' = 'true'
    and task.metadata->>'mission_kind' is null;

  insert into public.agent_mission_task_audit_snapshots(
    audit_batch_id, task_id, reason, previous_row
  )
  select v_batch, task.id, 'specific_overdue_requires_owner_revalidation', to_jsonb(task)
  from public.agent_mission_tasks task
  where task.status in ('backlog', 'blocked')
    and task.due_at < now()
    and coalesce(task.metadata->>'daily_learning', 'false') <> 'true'
    and coalesce(task.metadata->>'auto_practical_action', 'false') <> 'true'
    and coalesce(task.metadata->>'book_detail', 'false') <> 'true'
    and coalesce(task.metadata->>'needs_owner_revalidation', 'false') <> 'true';

  update public.agent_mission_tasks task
  set metadata = coalesce(task.metadata, '{}'::jsonb) || jsonb_build_object(
        'audit_classification', 'specific_overdue',
        'needs_owner_revalidation', true,
        'audit_classified_at', now(),
        'audit_classification_batch', v_batch
      ),
      updated_at = now()
  where task.status in ('backlog', 'blocked')
    and task.due_at < now()
    and coalesce(task.metadata->>'daily_learning', 'false') <> 'true'
    and coalesce(task.metadata->>'auto_practical_action', 'false') <> 'true'
    and coalesce(task.metadata->>'book_detail', 'false') <> 'true'
    and coalesce(task.metadata->>'needs_owner_revalidation', 'false') <> 'true';
end;
$finalize$;
