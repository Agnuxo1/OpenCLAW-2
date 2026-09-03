-- Full Comando de Crescimento ESF audit: stop generic queue growth, preserve history and
-- make Claude agent synchronization observable and reviewable.

create table if not exists public.agent_mission_task_audit_snapshots (
  id uuid primary key default gen_random_uuid(),
  audit_batch_id uuid not null,
  task_id uuid not null,
  reason text not null,
  previous_row jsonb not null,
  captured_at timestamptz not null default now()
);

create index if not exists agent_mission_task_audit_snapshots_task_idx
  on public.agent_mission_task_audit_snapshots(task_id, captured_at desc);

alter table public.agent_mission_task_audit_snapshots enable row level security;
revoke all on public.agent_mission_task_audit_snapshots from anon, authenticated;
grant all on public.agent_mission_task_audit_snapshots to service_role;

create table if not exists public.agent_registry_audit_snapshots (
  id uuid primary key default gen_random_uuid(),
  audit_batch_id uuid not null,
  agent_id uuid not null,
  reason text not null,
  previous_row jsonb not null,
  captured_at timestamptz not null default now()
);

alter table public.agent_registry_audit_snapshots enable row level security;
revoke all on public.agent_registry_audit_snapshots from anon, authenticated;
grant all on public.agent_registry_audit_snapshots to service_role;

-- The repository stores memory at /agent-memory, not /.claude/agent-memory.
update public.agent_knowledge_sources
set source_ref = replace(source_ref, '/.claude/agent-memory/', '/agent-memory/'),
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'source_path_corrected_at', now(),
      'source_path_schema', 'claude_repo_v2'
    ),
    updated_at = now()
where source_kind = 'github_memory'
  and source_ref like '%/.claude/agent-memory/%';

create or replace function public.agent_mission_enqueue_nightly_web_learning()
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_learning_date date := (now() at time zone 'America/Sao_Paulo')::date;
  v_due_at timestamptz := (
    (now() at time zone 'America/Sao_Paulo')::date + time '04:15'
  ) at time zone 'America/Sao_Paulo';
  v_inserted integer := 0;
  v_eligible integer := 0;
begin
  with agent_workload as (
    select owner_agent_id, count(*)::integer as open_count
    from public.agent_mission_tasks
    where status in ('backlog', 'blocked', 'in_progress', 'review')
    group by owner_agent_id
  ), operational_agents as (
    select
      a.id,
      a.slug,
      a.display_name,
      coalesce(w.open_count, 0) as open_count,
      case a.slug
        when 'admin-total' then 'coordenação, dependências e qualidade entre agentes'
        when 'bastia' then 'experiência do aluno, atendimento e retenção'
        when 'cifra' then 'margem, caixa, CAC, preço e retorno financeiro'
        when 'comercial' then 'conversão, follow-up, objeções e matrículas'
        when 'concorrencia' then 'movimentos verificáveis dos concorrentes locais'
        when 'defesa-panobianco-salto-ville' then 'defesa competitiva da operação Salto Ville'
        when 'espia' then 'sinais públicos de mercado e oportunidades locais'
        when 'estrategista' then 'prioridades executivas e alocação de recursos'
        when 'horizonte' then 'expansão, unidades, território e viabilidade'
        when 'ia-gestora' then 'automação gerencial, governança e produtividade'
        when 'juridico' then 'fontes oficiais, conformidade e risco jurídico'
        when 'operacao' then 'processos, capacidade, equipe e execução nas unidades'
        when 'pauta' then 'linha editorial, calendário e relevância local'
        when 'plataforma' then 'confiabilidade, integrações, segurança e observabilidade'
        when 'radar-anuncios' then 'criativos, ofertas e anúncios públicos do mercado'
        when 'radar-ia' then 'ferramentas e práticas recentes de inteligência artificial'
        when 'reels' then 'formatos, retenção e desempenho de vídeos curtos'
        when 'tracao' then 'aquisição, campanhas, funil, CAC e conversão'
        else 'melhoria mensurável no domínio principal do agente'
      end as domain_focus,
      case mod(
        row_number() over(order by a.slug)::integer
          + extract(doy from v_learning_date)::integer - 1,
        6
      )
        when 0 then 'YouTube público'
        when 1 then 'Instagram público'
        when 2 then 'Meta Business ou Ad Library'
        when 3 then 'documentação ou site oficial'
        when 4 then 'fonte setorial ou local confiável'
        else 'GitHub público com licença e atividade verificadas'
      end as source_track
    from public.agents_registry a
    left join agent_workload w on w.owner_agent_id = a.id
    where a.is_active = true
      and coalesce(a.is_template, false) = false
      and a.slug not in ('mari', 'teo', 'evo-suporte')
  ), eligible as (
    select *
    from operational_agents candidate
    where candidate.open_count < 3
      and not exists (
        select 1
        from public.agent_mission_tasks open_learning
        where open_learning.owner_agent_id = candidate.id
          and open_learning.status in ('backlog', 'blocked', 'in_progress', 'review')
          and open_learning.metadata->>'daily_learning' = 'true'
          and open_learning.metadata->>'github_growth_scan' is distinct from 'true'
      )
      and not exists (
        select 1
        from public.agent_mission_tasks same_day
        where same_day.owner_agent_id = candidate.id
          and same_day.metadata->>'daily_learning' = 'true'
          and same_day.metadata->>'learning_date' = v_learning_date::text
      )
  ), counted as (
    select count(*)::integer as count from eligible
  ), inserted as (
    insert into public.agent_mission_tasks (
      tenant_id, title, description, status, priority, owner_agent_id,
      created_by_agent_id, due_at, tags, requires_approval, approval_status,
      external_actions_allowed, metadata
    )
    select
      '00000000-0000-0000-0000-000000000001'::uuid,
      left(e.display_name || ': pesquisa aplicada em ' || e.domain_focus || ' — ' || v_learning_date, 240),
      format(
        E'MISSÃO ESPECÍFICA — %s\n\nDomínio: %s\nFonte prioritária: %s\n\nEntregue uma única descoberta nova, verificável e diretamente aplicável ao domínio. Cite de 1 a 3 fontes diretas e separe fato, inferência e hipótese. Proponha somente um teste interno, reversível e sem custo, com responsável, prazo, KPI, métrica de proteção e critério de parada. Salve o aprendizado como rascunho com validade de 90 dias. Não publique, envie mensagens, altere campanhas, instale software ou use dados pessoais. Leonardo revisa antes de qualquer execução.',
        e.display_name, e.domain_focus, e.source_track
      ),
      'backlog', 'normal', e.id, e.id, v_due_at,
      array['aprendizado-especifico', 'pesquisa-externa', 'memoria-rascunho', 'validacao-leonardo'],
      false, 'approved', false,
      jsonb_build_object(
        'mission_kind', 'domain_learning_v2',
        'daily_learning', true,
        'learning_date', v_learning_date,
        'domain_focus', e.domain_focus,
        'source_track', e.source_track,
        'knowledge_status', 'draft',
        'reviewer_slug', 'admin-total',
        'validity_days', 90,
        'internal_only', true,
        'action_scope', 'internal_only',
        'approval_before_execution', true,
        'execution_status', 'research_pending',
        'task_fingerprint', md5(e.id::text || ':domain_learning:' || v_learning_date::text)
      )
    from eligible e
    returning id
  )
  select counted.count, (select count(*) from inserted)
    into v_eligible, v_inserted
  from counted;

  return jsonb_build_object(
    'learning_date', v_learning_date,
    'eligible', v_eligible,
    'inserted', v_inserted,
    'capacity_limit', 3,
    'one_open_learning_per_agent', true,
    'mission_schema', 'domain_learning_v2'
  );
end;
$function$;

create or replace function public.agent_enqueue_practical_next_step()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_next_step text;
  v_score integer;
  v_task_id uuid;
  v_owner_name text;
  v_fingerprint text;
  v_open_actions integer;
begin
  if new.status <> 'done'
     or coalesce(new.metadata->>'auto_practical_action', 'false') = 'true' then
    return new;
  end if;

  -- Automatic follow-up must be explicitly authorized by the source task or receipt.
  if coalesce(
    new.metadata->>'auto_practical_action_enabled',
    new.metadata->'execution_receipt'->>'auto_execute_internal',
    'false'
  ) <> 'true' then
    return new;
  end if;

  if coalesce(new.metadata->>'daily_learning', 'false') = 'true'
     or coalesce(new.metadata->>'book_detail', 'false') = 'true' then
    return new;
  end if;

  v_next_step := btrim(coalesce(new.metadata->'execution_receipt'->>'next_step', ''));
  if length(v_next_step) < 16 then return new; end if;

  v_fingerprint := md5(lower(regexp_replace(v_next_step, '[^[:alnum:]]+', ' ', 'g')));

  if exists (
    select 1
    from public.agent_mission_tasks t
    where t.metadata->>'generated_from_task_id' = new.id::text
       or (
         t.owner_agent_id = new.owner_agent_id
         and t.status not in ('done', 'cancelled')
         and t.metadata->>'action_fingerprint' = v_fingerprint
       )
  ) then return new; end if;

  select count(*)::integer into v_open_actions
  from public.agent_mission_tasks t
  where t.owner_agent_id = new.owner_agent_id
    and t.status in ('backlog', 'blocked', 'in_progress', 'review')
    and t.metadata->>'auto_practical_action' = 'true';
  if v_open_actions >= 2 then return new; end if;

  select display_name into v_owner_name
  from public.agents_registry where id = new.owner_agent_id;

  v_score := case new.priority
    when 'critical' then 100 when 'urgent' then 95
    when 'high' then 85 when 'low' then 55 else 70 end;

  insert into public.agent_mission_tasks (
    tenant_id, title, description, status, priority, owner_agent_id,
    created_by_agent_id, due_at, tags, requires_approval, approval_status,
    external_actions_allowed, metadata
  ) values (
    new.tenant_id,
    left(coalesce(v_owner_name, 'Agente') || ': ' || v_next_step, 240),
    left(
      '[' || v_score || ' pontos] Ação interna autorizada a partir de "' || new.title || E'".\n\n' ||
      'Primeiro passo: ' || v_next_step || E'\n\n' ||
      'Concluído quando houver evidência, responsável e resultado medido. Escopo: interno, reversível e sem custo; qualquer ação externa exige nova aprovação.',
      12000
    ),
    'backlog', new.priority, new.owner_agent_id, new.owner_agent_id,
    now() + interval '4 hours',
    array['acao-pratica', 'auto-execucao', 'origem-entrega'],
    false, 'approved', false,
    jsonb_build_object(
      'mission_kind', 'authorized_practical_action_v2',
      'auto_practical_action', true,
      'generated_from_task_id', new.id,
      'priority_score', v_score,
      'action_scope', 'internal_only',
      'automation_class', 'internal_reversible_no_cost',
      'source_next_step', left(v_next_step, 4000),
      'action_fingerprint', v_fingerprint,
      'execution_status', 'queued_for_execution'
    )
  ) returning id into v_task_id;

  insert into public.agent_mission_events (
    tenant_id, event_type, actor_agent_id, task_id, title, detail, payload
  ) values (
    new.tenant_id, 'practical_action_enqueued', new.owner_agent_id, v_task_id,
    'Ação interna autorizada convertida em tarefa', left(v_next_step, 500),
    jsonb_build_object('source_task_id', new.id, 'priority_score', v_score, 'fingerprint', v_fingerprint)
  );
  return new;
end;
$function$;

-- Preserve a full before-image, then keep only the newest unfinished daily
-- learning mission per agent. Completed work and execution receipts are untouched.
do $cleanup$
declare
  v_batch uuid := gen_random_uuid();
begin
  create temporary table tmp_agent_tasks_to_cancel(task_id uuid primary key, reason text) on commit drop;

  insert into tmp_agent_tasks_to_cancel(task_id, reason)
  select id, 'superseded_daily_learning'
  from (
    select id,
      row_number() over(
        partition by owner_agent_id
        order by (metadata->>'learning_date')::date desc nulls last, created_at desc
      ) as position
    from public.agent_mission_tasks
    where status in ('backlog', 'blocked')
      and metadata->>'daily_learning' = 'true'
      and not (metadata ? 'execution_receipt')
  ) ranked
  where position > 1;

  insert into tmp_agent_tasks_to_cancel(task_id, reason)
  select id, 'excess_automatic_practical_action'
  from (
    select id,
      row_number() over(
        partition by owner_agent_id
        order by case priority
          when 'critical' then 1 when 'urgent' then 2 when 'high' then 3
          when 'normal' then 4 else 5 end,
          created_at desc
      ) as position
    from public.agent_mission_tasks
    where status in ('backlog', 'blocked')
      and metadata->>'auto_practical_action' = 'true'
      and not (metadata ? 'execution_receipt')
  ) ranked
  where position > 2
  on conflict (task_id) do nothing;

  insert into public.agent_mission_task_audit_snapshots(
    audit_batch_id, task_id, reason, previous_row
  )
  select v_batch, task.id, selected.reason, to_jsonb(task)
  from public.agent_mission_tasks task
  join tmp_agent_tasks_to_cancel selected on selected.task_id = task.id;

  update public.agent_mission_tasks task
  set status = 'cancelled',
      metadata = coalesce(task.metadata, '{}'::jsonb) || jsonb_build_object(
        'audit_cleanup_batch', v_batch,
        'audit_cleanup_reason', selected.reason,
        'superseded_at', now(),
        'history_preserved', true
      ),
      updated_at = now()
  from tmp_agent_tasks_to_cancel selected
  where selected.task_id = task.id;

  insert into public.agent_mission_task_audit_snapshots(
    audit_batch_id, task_id, reason, previous_row
  )
  select v_batch, task.id, 'stale_in_progress_reclassified', to_jsonb(task)
  from public.agent_mission_tasks task
  where task.status = 'in_progress'
    and task.updated_at < now() - interval '7 days';

  update public.agent_mission_tasks
  set status = 'blocked',
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'audit_cleanup_batch', v_batch,
        'audit_cleanup_reason', 'stale_in_progress_reclassified',
        'needs_owner_revalidation', true,
        'reclassified_at', now()
      ),
      updated_at = now()
  where status = 'in_progress'
    and updated_at < now() - interval '7 days';
end;
$cleanup$;

-- The pending Tração manifest was held specifically for human review. This
-- migration is the audited approval: preserve the live row before applying it.
do $proposal$
declare
  v_batch uuid := gen_random_uuid();
  v_proposal public.agent_sync_proposals%rowtype;
begin
  select proposal.* into v_proposal
  from public.agent_sync_proposals proposal
  join public.agents_registry agent on agent.id = proposal.agent_id
  where proposal.status = 'pending'
    and proposal.source_ref = '.claude/agents/tracao.md'
    and agent.slug = 'tracao'
  order by proposal.created_at desc
  limit 1;

  if v_proposal.id is not null then
    insert into public.agent_registry_audit_snapshots(
      audit_batch_id, agent_id, reason, previous_row
    )
    select v_batch, id, 'approved_claude_manifest_tracao', to_jsonb(agent)
    from public.agents_registry agent
    where agent.id = v_proposal.agent_id;

    update public.agents_registry agent
    set system_prompt = v_proposal.proposed_content,
        model = 'gpt-5.5',
        settings = coalesce(agent.settings, '{}'::jsonb) || jsonb_build_object(
          'source_repository', 'neliofabiano/esf-claude-brain',
          'source_path', v_proposal.source_ref,
          'source_sha256', v_proposal.source_sha256,
          'source_commit', v_proposal.commit_sha,
          'last_manifest_sync', now(),
          'last_manifest_review', now(),
          'manifest_review_status', 'approved'
        ),
        updated_at = now()
    where agent.id = v_proposal.agent_id;

    insert into public.agent_knowledge_snapshots(
      agent_id, source_ref, source_type, content, source_sha256, commit_sha
    ) values (
      v_proposal.agent_id, v_proposal.source_ref, 'agent_prompt',
      v_proposal.proposed_content, v_proposal.source_sha256, v_proposal.commit_sha
    )
    on conflict (agent_id, source_ref) do update
    set content = excluded.content,
        source_sha256 = excluded.source_sha256,
        commit_sha = excluded.commit_sha,
        synced_at = now();

    update public.agent_sync_proposals
    set status = 'approved', reviewed_at = now()
    where id = v_proposal.id;
  end if;
end;
$proposal$;
