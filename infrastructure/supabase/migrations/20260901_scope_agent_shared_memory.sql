-- Bridge existing Claude agent memories into Comando de Crescimento ESF with explicit read ACLs.
-- The existing github_agent inheritance is the source of truth for who may read whom.

insert into public.agent_knowledge_sources (
  agent_id,
  source_kind,
  source_ref,
  access_mode,
  priority,
  metadata
)
select distinct
  source.agent_id,
  'github_memory',
  replace(
    replace(source.source_ref, '/.claude/agents/', '/.claude/agent-memory/'),
    '.md',
    '/MEMORY.md'
  ),
  'read_only',
  source.priority,
  source.metadata || jsonb_build_object(
    'bridge', 'claude_openclaw_v1',
    'memory_agent_slug', memory.agent_slug,
    'local_legal_memory_excluded', true
  )
from public.agent_knowledge_sources source
cross join lateral (
  select substring(source.source_ref from '/agents/([^/]+)\.md$') as agent_slug
) memory
where source.source_kind = 'github_agent'
  and memory.agent_slug is not null
  and memory.agent_slug !~ '^juridico(-|$)'
  and exists (
    select 1
    from public.claude_memory_index indexed
    where indexed.scope = 'squad_agent'
      and indexed.agent_slug = memory.agent_slug
  )
on conflict (agent_id, source_kind, source_ref) do update
set access_mode = excluded.access_mode,
    priority = excluded.priority,
    metadata = public.agent_knowledge_sources.metadata || excluded.metadata,
    updated_at = now();

-- Leonardo receives the two executive memories needed for orchestration, not every
-- specialist's raw memory and not the broad claude_main scope.
insert into public.agent_knowledge_sources (
  agent_id,
  source_kind,
  source_ref,
  access_mode,
  priority,
  metadata
)
select
  admin.id,
  'github_memory',
  'neliofabiano/esf-claude-brain/.claude/agent-memory/' || memory.agent_slug || '/MEMORY.md',
  'read_only',
  memory.priority,
  jsonb_build_object(
    'bridge', 'claude_openclaw_v1',
    'memory_agent_slug', memory.agent_slug,
    'relationship', 'executive_memory',
    'local_legal_memory_excluded', true
  )
from public.agents_registry admin
cross join (values ('estrategista', 95::smallint), ('operacao', 90::smallint)) memory(agent_slug, priority)
where admin.slug = 'admin-total'
  and exists (
    select 1
    from public.claude_memory_index indexed
    where indexed.scope = 'squad_agent'
      and indexed.agent_slug = memory.agent_slug
  )
on conflict (agent_id, source_kind, source_ref) do update
set access_mode = excluded.access_mode,
    priority = excluded.priority,
    metadata = public.agent_knowledge_sources.metadata || excluded.metadata,
    updated_at = now();

create or replace function public.agent_search_general_memory_ranked_v5(
  p_requesting_agent_id uuid,
  p_query text,
  p_top_k integer default 3
)
returns jsonb
language sql
stable
set search_path to ''
as $function$
  with normalized as (
    select nullif(trim(p_query), '') as query_text,
           greatest(1, least(coalesce(p_top_k, 3), 3)) as result_limit,
           public.agent_memory_route_query(p_query) as routed_collection
  ), requester as (
    select id, slug
    from public.agents_registry
    where id = p_requesting_agent_id
    limit 1
  ), accessible_memory_sources as (
    select requester.slug as agent_slug, 100::smallint as priority
    from requester
    union
    select source.metadata ->> 'memory_agent_slug' as agent_slug,
           max(source.priority)::smallint as priority
    from public.agent_knowledge_sources source
    where source.agent_id = p_requesting_agent_id
      and source.source_kind = 'github_memory'
      and source.access_mode in ('read_only', 'read_write')
      and nullif(source.metadata ->> 'memory_agent_slug', '') is not null
    group by source.metadata ->> 'memory_agent_slug'
  ), tokens as (
    select token
    from (
      select distinct part as token
      from normalized
      cross join lateral regexp_split_to_table(
        public.agent_memory_normalize(normalized.query_text),
        '[^[:alnum:]_]+'
      ) as part
      where normalized.query_text is not null
        and length(part) >= 3
        and part not in (
          'ainda','aqui','assim','como','com','das','dos','ela','ele','esta','esse',
          'isso','mais','mas','nao','nos','para','pela','pelo','por','que','sem',
          'ser','tem','uma','vamos','voce'
        )
      order by part
      limit 12
    ) distinct_tokens
  ), search_query as (
    select to_tsquery(
      'simple'::regconfig,
      coalesce(string_agg(token || ':*', ' | '), '__memoria_sem_resultado__')
    ) as query
    from tokens
  ), note_candidates as (
    select 'nota_curada'::text as source_type,
      note.id, note.agent_id, agent.slug as agent_slug,
      agent.display_name as agent_name, note.title, note.slug,
      left(note.content, 2600) as content, note.tags,
      coalesce(note.metadata, '{}'::jsonb) || jsonb_build_object(
        'collection', note.collection,
        'source_name', note.source_name,
        'unit', note.unit,
        'responsible', note.responsible,
        'memory_version', note.memory_version,
        'historical_data_only', true
      ) as metadata,
      note.updated_at as occurred_at,
      (
        case when note.collection = normalized.routed_collection then 5.0 else 0.0 end
        + 2.2 * ts_rank_cd(
          setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(coalesce(note.title, ''))), 'A') ||
          setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(array_to_string(note.tags, ' '))), 'A') ||
          setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(coalesce(note.source_name, ''))), 'B') ||
          setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(left(coalesce(note.content, ''), 6000))), 'C'),
          search_query.query,
          32
        )
        + note.priority::numeric / 250.0
        + case when normalized.routed_collection = 'operacao_evo' and agent.slug = 'evo-conhecimento' then 1.5 else 0 end
        + case when note.source_name ~* '(oficial|manual|evo|gest[aã]o)' then 0.35 else 0 end
      )::double precision as match_rank
    from public.agent_notes note
    join public.agents_registry agent on agent.id = note.agent_id
    cross join normalized
    cross join search_query
    cross join requester
    where note.archived = false
      and note.approval_status = 'approved'
      and (note.valid_until is null or note.valid_until >= current_date)
      and (
        'all_agents' = any(note.allowed_audiences)
        or requester.slug = any(note.allowed_audiences)
        or requester.slug = 'admin-total'
      )
      and (normalized.routed_collection is null or note.collection = normalized.routed_collection)
      and (
        setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(coalesce(note.title, ''))), 'A') ||
        setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(array_to_string(note.tags, ' '))), 'A') ||
        setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(coalesce(note.source_name, ''))), 'B') ||
        setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(left(coalesce(note.content, ''), 6000))), 'C')
      ) @@ search_query.query
    order by match_rank desc, note.updated_at desc
    limit (select result_limit * 6 from normalized)
  ), conversation_candidates as (
    select 'conversa_historica'::text as source_type,
      message.id, session.agent_id, agent.slug as agent_slug,
      agent.display_name as agent_name,
      coalesce(nullif(trim(session.title), ''), 'Conversa') as title,
      null::text as slug, left(message.content, 1600) as content,
      array[]::text[] as tags,
      jsonb_build_object(
        'session_id', session.id,
        'role', message.role,
        'channel', session.channel,
        'agent_active', agent.is_active,
        'historical_data_only', true,
        'access_scope', 'knowledge_source_acl'
      ) as metadata,
      message.created_at as occurred_at,
      ts_rank_cd(
        to_tsvector('simple'::regconfig, public.agent_memory_normalize(coalesce(message.content, ''))),
        search_query.query,
        32
      )::double precision as match_rank
    from public.agents_messages message
    join public.agents_sessions session on session.id = message.session_id
    join public.agents_registry agent on agent.id = session.agent_id
    join accessible_memory_sources access on access.agent_slug = agent.slug
    cross join normalized
    cross join search_query
    where normalized.routed_collection is null
      and message.role in ('user', 'assistant')
      and message.status = 'completed'
      and length(trim(message.content)) >= 12
      and message.content !~* '(senha|password|api.?key|token|credencial|service.?role|authorization|jwt)'
      and to_tsvector(
        'simple'::regconfig,
        public.agent_memory_normalize(coalesce(message.content, ''))
      ) @@ search_query.query
    order by match_rank desc, message.created_at desc
    limit (select result_limit * 3 from normalized)
  ), claude_memory_candidates as (
    select 'claude_memory'::text as source_type,
      memory.id, agent.id as agent_id, memory.agent_slug,
      agent.display_name as agent_name, memory.title, memory.slug,
      left(memory.content, 2200) as content,
      array[memory.memory_type, memory.scope]::text[] as tags,
      jsonb_build_object(
        'scope', memory.scope,
        'memory_type', memory.memory_type,
        'source_name', 'claude_agent_memory',
        'access_scope', 'knowledge_source_acl',
        'historical_data_only', true
      ) as metadata,
      memory.updated_at as occurred_at,
      (
        4.0 * ts_rank_cd(
          setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(memory.title)), 'A') ||
          setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(left(memory.content, 6000))), 'C'),
          search_query.query,
          32
        ) + access.priority::numeric / 300.0
      )::double precision as match_rank
    from public.claude_memory_index memory
    join accessible_memory_sources access on access.agent_slug = memory.agent_slug
    join public.agents_registry agent on agent.slug = memory.agent_slug
    cross join normalized
    cross join search_query
    where normalized.routed_collection is null
      and memory.scope = 'squad_agent'
      and memory.content !~ '(sk-[A-Za-z0-9_-]{20,}|sb_secret_[A-Za-z0-9_-]{20,}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})'
      and (
        setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(memory.title)), 'A') ||
        setweight(to_tsvector('simple'::regconfig, public.agent_memory_normalize(left(memory.content, 6000))), 'C')
      ) @@ search_query.query
    order by match_rank desc, memory.updated_at desc
    limit (select result_limit * 4 from normalized)
  ), combined as (
    select * from note_candidates
    union all
    select * from conversation_candidates
    union all
    select * from claude_memory_candidates
  ), deduplicated as (
    select combined.*,
      row_number() over (
        partition by md5(lower(regexp_replace(trim(combined.content), '\s+', ' ', 'g')))
        order by combined.match_rank desc, combined.occurred_at desc
      ) as duplicate_rank
    from combined
  ), final_results as (
    select *
    from deduplicated
    where duplicate_rank = 1
    order by match_rank desc, occurred_at desc
    limit (select result_limit from normalized)
  )
  select jsonb_build_object(
    'ok', true,
    'version', 'general-memory-v5-scoped-claude-bridge',
    'scope', 'audience-and-knowledge-source-acl',
    'requesting_agent_id', p_requesting_agent_id,
    'query', p_query,
    'routed_collection', (select routed_collection from normalized),
    'max_results', 3,
    'results', coalesce(jsonb_agg(jsonb_build_object(
      'source_type', final_results.source_type,
      'id', final_results.id,
      'agent_id', final_results.agent_id,
      'agent_slug', final_results.agent_slug,
      'agent_name', final_results.agent_name,
      'title', final_results.title,
      'slug', final_results.slug,
      'content', final_results.content,
      'tags', final_results.tags,
      'metadata', final_results.metadata,
      'occurred_at', final_results.occurred_at,
      'match_rank', final_results.match_rank
    ) order by final_results.match_rank desc, final_results.occurred_at desc), '[]'::jsonb)
  )
  from final_results;
$function$;

revoke all on function public.agent_search_general_memory_ranked_v5(uuid, text, integer) from public, anon, authenticated;
grant execute on function public.agent_search_general_memory_ranked_v5(uuid, text, integer) to service_role;

create or replace function public.agent_search_general_memory(
  p_requesting_agent_id uuid,
  p_query text,
  p_top_k integer default 3
)
returns jsonb
language plpgsql
stable
set search_path to ''
as $function$
declare
  v_payload jsonb;
  v_unit text := public.agent_memory_route_unit(p_query);
  v_collection text;
  v_filtered jsonb;
  v_official jsonb;
begin
  v_payload := public.agent_search_general_memory_ranked_v5(
    p_requesting_agent_id,
    p_query,
    p_top_k
  );
  v_collection := v_payload ->> 'routed_collection';

  if v_unit is not null then
    select coalesce(jsonb_agg(item), '[]'::jsonb)
      into v_filtered
    from jsonb_array_elements(coalesce(v_payload -> 'results', '[]'::jsonb)) item
    where item #>> '{metadata,unit}' = v_unit;

    if jsonb_array_length(v_filtered) > 0 then
      v_payload := jsonb_set(v_payload, '{results}', v_filtered, true)
        || jsonb_build_object('routed_unit', v_unit);
    end if;
  end if;

  if v_collection in ('grade_aulas', 'planos_vigentes') then
    select coalesce(jsonb_agg(item), '[]'::jsonb)
      into v_official
    from jsonb_array_elements(coalesce(v_payload -> 'results', '[]'::jsonb)) item
    where item #>> '{metadata,source_name}' like 'config:mari_mod_%';

    if jsonb_array_length(v_official) > 0 then
      v_payload := jsonb_set(v_payload, '{results}', v_official, true)
        || jsonb_build_object('official_source_only', true);
    end if;
  end if;

  return v_payload;
end;
$function$;

comment on function public.agent_search_general_memory_ranked_v5(uuid, text, integer) is
  'Retrieves curated, conversation, and Claude squad memory using audience and agent_knowledge_sources ACLs.';
