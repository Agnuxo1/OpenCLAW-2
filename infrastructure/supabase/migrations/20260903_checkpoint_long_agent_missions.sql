-- Keep useful evidence when a long agent run approaches the Edge timeout.
do $checkpoint_protocol$
declare
  v_definition text;
  v_anchor text := 'Chame mission_get_work agora e trabalhe a missão de maior prioridade.';
  v_replacement text := 'Chame mission_get_work agora e trabalhe a missão de maior prioridade. Em até 90 segundos, salve um checkpoint com fontes, números e próximo passo; no ciclo inicial use no máximo duas delegações e submeta um recibo parcial antes de 130 segundos, continuando em outro ciclo quando necessário.';
begin
  select pg_get_functiondef(
    'public.agent_mission_dispatch_cycle_unlocked(integer)'::regprocedure
  ) into v_definition;

  if position(v_anchor in v_definition) = 0 then
    raise exception 'Dispatch instruction anchor was not found';
  end if;

  execute replace(v_definition, v_anchor, v_replacement);
end;
$checkpoint_protocol$;
