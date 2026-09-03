-- Internal AI manager routing data must only be reachable by backend services.
alter table public.gerente_ia_grupos_unidade enable row level security;
revoke all on public.gerente_ia_grupos_unidade from anon, authenticated;
grant all on public.gerente_ia_grupos_unidade to service_role;
