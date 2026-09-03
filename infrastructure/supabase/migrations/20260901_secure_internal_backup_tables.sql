-- These operational/backup tables are internal. Their default grants exposed all
-- operations, including TRUNCATE, to API roles. Service jobs retain owner/service
-- access; retention jobs use SECURITY DEFINER functions and continue to work.

alter table public.wa_scheduled_messages_bkp_20260831
  enable row level security;

alter table public.retencao_resgate_naorenovados_jul_ago2026
  enable row level security;

alter table public._bkp_rh_external_sync_queue_31ago
  enable row level security;

revoke all privileges on table public.wa_scheduled_messages_bkp_20260831
  from anon, authenticated;

revoke all privileges on table public.retencao_resgate_naorenovados_jul_ago2026
  from anon, authenticated;

revoke all privileges on table public._bkp_rh_external_sync_queue_31ago
  from anon, authenticated;
