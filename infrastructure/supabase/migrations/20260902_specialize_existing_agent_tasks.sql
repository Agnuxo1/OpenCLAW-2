-- Specialize the retained queue so Comando de Crescimento ESF no longer displays generic
-- task titles, and index the predicates used by the guarded generators.

create index if not exists agent_mission_tasks_open_daily_owner_idx
  on public.agent_mission_tasks(owner_agent_id, created_at desc)
  where status in ('backlog', 'blocked', 'in_progress', 'review')
    and metadata->>'daily_learning' = 'true';

create index if not exists agent_mission_tasks_open_practical_owner_idx
  on public.agent_mission_tasks(owner_agent_id, created_at desc)
  where status in ('backlog', 'blocked', 'in_progress', 'review')
    and metadata->>'auto_practical_action' = 'true';

create index if not exists agent_mission_tasks_action_fingerprint_idx
  on public.agent_mission_tasks(owner_agent_id, (metadata->>'action_fingerprint'))
  where status not in ('done', 'cancelled')
    and metadata->>'auto_practical_action' = 'true';

create index if not exists agent_registry_audit_snapshots_agent_idx
  on public.agent_registry_audit_snapshots(agent_id, captured_at desc);

do $specialize$
declare
  v_batch uuid := gen_random_uuid();
begin
  insert into public.agent_mission_task_audit_snapshots(
    audit_batch_id, task_id, reason, previous_row
  )
  select v_batch, task.id, 'specialized_retained_task_title', to_jsonb(task)
  from public.agent_mission_tasks task
  where task.status in ('backlog', 'blocked', 'in_progress', 'review')
    and (
      task.title like 'Aprendizado web diário%'
      or task.title like 'Executar plano%'
    );

  with specialized as (
    select
      task.id,
      agent.display_name,
      case agent.slug
        when 'admin-total' then 'coordenação e qualidade entre agentes'
        when 'bastia' then 'experiência e retenção de alunos'
        when 'cifra' then 'margem, caixa, CAC e retorno'
        when 'comercial' then 'conversão, follow-up e matrículas'
        when 'concorrencia' then 'movimentos dos concorrentes locais'
        when 'defesa-panobianco-salto-ville' then 'defesa competitiva de Salto Ville'
        when 'espia' then 'sinais públicos e oportunidades locais'
        when 'estrategista' then 'prioridades e alocação de recursos'
        when 'horizonte' then 'expansão e viabilidade de unidades'
        when 'ia-gestora' then 'automação gerencial e governança'
        when 'juridico' then 'fontes oficiais e risco jurídico'
        when 'operacao' then 'processos, capacidade e execução'
        when 'pauta' then 'linha editorial e relevância local'
        when 'plataforma' then 'integrações, segurança e observabilidade'
        when 'radar-anuncios' then 'criativos e ofertas públicas do mercado'
        when 'radar-ia' then 'ferramentas e práticas recentes de IA'
        when 'reels' then 'retenção e desempenho de vídeos curtos'
        when 'tracao' then 'aquisição, funil, CAC e conversão'
        else 'melhoria mensurável no domínio do agente'
      end as domain_focus
    from public.agent_mission_tasks task
    join public.agents_registry agent on agent.id = task.owner_agent_id
    where task.status in ('backlog', 'blocked', 'in_progress', 'review')
      and task.title like 'Aprendizado web diário%'
  )
  update public.agent_mission_tasks task
  set title = left(
        specialized.display_name || ': pesquisa aplicada em ' || specialized.domain_focus ||
        ' — ' || coalesce(task.metadata->>'learning_date', to_char(task.created_at at time zone 'America/Sao_Paulo', 'YYYY-MM-DD')),
        240
      ),
      description = left(
        'DOMÍNIO PRIORITÁRIO: ' || specialized.domain_focus || E'\n\n' || task.description,
        12000
      ),
      tags = array_append(array_remove(task.tags, 'aprendizado-diario'), 'aprendizado-especifico'),
      metadata = coalesce(task.metadata, '{}'::jsonb) || jsonb_build_object(
        'mission_kind', 'domain_learning_v2',
        'domain_focus', specialized.domain_focus,
        'specialized_at', now(),
        'specialization_audit_batch', v_batch
      ),
      updated_at = now()
  from specialized
  where specialized.id = task.id;

  with practical as (
    select task.id, agent.display_name,
      nullif(btrim(task.metadata->>'source_next_step'), '') as next_step
    from public.agent_mission_tasks task
    join public.agents_registry agent on agent.id = task.owner_agent_id
    where task.status in ('backlog', 'blocked', 'in_progress', 'review')
      and task.title like 'Executar plano%'
      and task.metadata->>'auto_practical_action' = 'true'
  )
  update public.agent_mission_tasks task
  set title = left(
        practical.display_name || ': ' || coalesce(practical.next_step, regexp_replace(task.title, '^Executar plano — ', '')),
        240
      ),
      metadata = coalesce(task.metadata, '{}'::jsonb) || jsonb_build_object(
        'mission_kind', 'authorized_practical_action_v2',
        'action_fingerprint', md5(lower(regexp_replace(
          coalesce(practical.next_step, task.title), '[^[:alnum:]]+', ' ', 'g'
        ))),
        'specialized_at', now(),
        'specialization_audit_batch', v_batch
      ),
      updated_at = now()
  from practical
  where practical.id = task.id;
end;
$specialize$;
