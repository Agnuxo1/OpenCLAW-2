-- Make the official unit identifiers part of governed shared context.
update public.growth_system_config
set operating_principles = operating_principles || jsonb_build_object(
      'official_unit_mapping', jsonb_build_object(
        'Prime', 1,
        'Pelé', 5,
        'Nações', 7
      ),
      'unit_scope_validation_required', true
    ),
    updated_at = now()
where singleton;

insert into public.agent_notes(
  agent_id, title, slug, content, tags, metadata, collection, source_name,
  responsible, valid_until, allowed_audiences, approval_status, priority
)
select
  leonardo.id,
  'Mapa oficial das unidades ESF',
  'official-esf-unit-branch-mapping-v1',
  'Use este mapeamento em toda consulta, observação e experimento: Prime = id_branch/unidade_branch 1; Pelé = 5; Nações = 7. Antes de aceitar uma evidência por unidade, Leonardo deve conferir o identificador consultado. Evidência com unidade divergente deve ser rejeitada e medida novamente.',
  array['comando-crescimento-esf', 'data-quality', 'unit-mapping'],
  jsonb_build_object(
    'operating_system', 'Comando de Crescimento ESF',
    'contract_version', 1,
    'official_mapping', jsonb_build_object('Prime', 1, 'Pelé', 5, 'Nações', 7),
    'required_gate', 'unit_scope_validation'
  ),
  'historico_operacional', 'Comando de Crescimento ESF', 'Leonardo',
  current_date + 365,
  array[
    'admin-total', 'estrategista', 'tracao', 'comercial', 'bastia',
    'operacao', 'cifra', 'plataforma', 'espia', 'concorrencia'
  ],
  'approved', 100
from public.agents_registry leonardo
where leonardo.slug = 'admin-total' and leonardo.is_active
on conflict (agent_id, slug) do update
set content = excluded.content,
    tags = excluded.tags,
    metadata = excluded.metadata,
    valid_until = excluded.valid_until,
    allowed_audiences = excluded.allowed_audiences,
    approval_status = excluded.approval_status,
    priority = excluded.priority,
    archived = false,
    updated_at = now();

update public.growth_experiments experiment
set metadata = experiment.metadata || jsonb_build_object(
      'official_unit_mapping', jsonb_build_object('Prime', 1, 'Pelé', 5, 'Nações', 7),
      'unit_scope_validation_required', true
    ),
    updated_at = now()
where experiment.status in ('planned', 'running');

update public.agent_mission_tasks task
set metadata = task.metadata || jsonb_build_object(
      'official_unit_mapping', jsonb_build_object('Prime', 1, 'Pelé', 5, 'Nações', 7),
      'unit_scope_validation_required', true
    ),
    updated_at = now()
where task.metadata->>'mission_kind' = 'growth_experiment_v1'
  and task.status in ('backlog', 'in_progress', 'review');
