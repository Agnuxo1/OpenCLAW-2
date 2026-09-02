import { createClient } from "npm:@supabase/supabase-js@2.57.4";

type AgentManifest = {
  slug: string;
  model: string;
  source_path: string;
  source_sha256: string;
  content?: string;
  memory_content?: string | null;
  memory_sha256?: string | null;
};

const TOKEN_HASH = "d412c3c4fd077b0db2e9ec8131b80225df934500dafe4e7173428ee8718d8406";
const PROTECTED = new Set([
  "mari",
  "teo",
  "juridico",
  "juridico-analise",
  "juridico-jurisprudencia",
  "juridico-pesquisa",
]);

async function sha256(value: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST required" }), { status: 405 });
  }
  if (await sha256(request.headers.get("x-agent-sync-token") ?? "") !== TOKEN_HASH) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const payload = await request.json();
  const agents = Array.isArray(payload.agents) ? payload.agents as AgentManifest[] : [];
  if (payload.repository !== "neliofabiano/esf-claude-brain" || !agents.length) {
    return new Response(JSON.stringify({ error: "invalid manifest" }), { status: 400 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
  const now = () => new Date().toISOString();
  const { data: run, error: runError } = await supabase.from("agent_sync_runs").insert({
    repository: payload.repository,
    commit_sha: payload.commit_sha ?? null,
    status: "started",
    agents_seen: agents.length,
  }).select("id").single();
  if (runError) return new Response(JSON.stringify({ error: runError.message }), { status: 500 });

  let updated = 0;
  let skipped = 0;
  let proposals = 0;
  let memoriesSynced = 0;
  const memoryErrors: string[] = [];

  for (const manifest of agents) {
    const slug = manifest.slug.toLowerCase();
    const { data: registry } = await supabase.from("agents_registry")
      .select("id,is_active,settings")
      .eq("slug", manifest.slug)
      .eq("provider", "openai_codex")
      .maybeSingle();

    // Memory is synchronized for active and protected agents alike. Access is
    // still constrained by agent_knowledge_sources in Mission Control.
    if (manifest.memory_content) {
      const memorySource = `agent-memory/${manifest.slug}/MEMORY.md`;
      if (registry) {
        await supabase.from("agent_knowledge_snapshots").upsert({
          agent_id: registry.id,
          source_ref: memorySource,
          source_type: "agent_memory",
          content: manifest.memory_content,
          source_sha256: manifest.memory_sha256 ?? await sha256(manifest.memory_content),
          commit_sha: payload.commit_sha ?? null,
          synced_at: now(),
        }, { onConflict: "agent_id,source_ref" });
      }

      try {
        const response = await fetch(`${supabaseUrl}/functions/v1/claude-memory-index`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${serviceRoleKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            action: "sync",
            rows: [{
              scope: "squad_agent",
              agent_slug: manifest.slug,
              memory_type: "main_memory",
              slug: "MEMORY",
              title: `${manifest.slug} persistent memory`,
              content: manifest.memory_content,
            }],
          }),
        });
        const result = await response.json();
        if (!response.ok || result.errors?.length) {
          memoryErrors.push(`${manifest.slug}: ${result.error ?? result.errors?.join(", ") ?? response.status}`);
        } else {
          memoriesSynced += Number(result.upserted ?? 0) + Number(result.skipped_unchanged ?? 0);
        }
      } catch (error) {
        memoryErrors.push(`${manifest.slug}: ${error instanceof Error ? error.message : String(error)}`);
      }
    }

    if (PROTECTED.has(slug)) {
      skipped++;
      continue;
    }
    if (!registry) continue;

    const timestamp = now();
    if (registry.settings?.source_sha256 === manifest.source_sha256) {
      await supabase.from("agent_manifest_sources").update({ last_synced_at: timestamp }).eq("agent_id", registry.id);
      continue;
    }

    const settings = {
      ...(registry.settings ?? {}),
      source_repository: payload.repository,
      source_path: manifest.source_path,
      source_sha256: manifest.source_sha256,
      source_commit: payload.commit_sha ?? null,
      last_manifest_sync: timestamp,
    };
    if (registry.is_active && manifest.content) {
      await supabase.from("agent_sync_proposals").upsert({
        agent_id: registry.id,
        source_ref: manifest.source_path,
        proposed_content: manifest.content,
        source_sha256: manifest.source_sha256,
        commit_sha: payload.commit_sha ?? null,
        synced_at: now(),
        reason: "active_agent_requires_review",
        status: "pending",
      }, { onConflict: "agent_id,source_ref,source_sha256" });
      proposals++;
    } else if (manifest.content) {
      await supabase.from("agents_registry").update({
        model: "gpt-5.5",
        system_prompt: manifest.content,
        settings,
      }).eq("id", registry.id);
      await supabase.from("agent_knowledge_snapshots").upsert({
        agent_id: registry.id,
        source_ref: manifest.source_path,
        source_type: "agent_prompt",
        content: manifest.content,
        source_sha256: manifest.source_sha256,
        commit_sha: payload.commit_sha ?? null,
      }, { onConflict: "agent_id,source_ref" });
      updated++;
    }
    await supabase.from("agent_manifest_sources").upsert({
      agent_id: registry.id,
      repository: payload.repository,
      branch: "main",
      source_path: manifest.source_path,
      source_sha256: manifest.source_sha256,
      source_model: "gpt-5.5",
      sync_mode: registry.is_active ? "manual_review" : "catalog_only",
      protected_from_auto_sync: registry.is_active,
      last_synced_at: timestamp,
      metadata: { source_commit: payload.commit_sha ?? null },
    });
  }

  await supabase.from("agent_sync_runs").update({
    status: memoryErrors.length ? "completed_with_warnings" : "completed",
    agents_updated: updated,
    protected_skipped: skipped,
    finished_at: now(),
    details: {
      mode: "automatic_safe_with_memory",
      pending_proposals: proposals,
      memories_synced: memoriesSynced,
      memory_errors: memoryErrors.slice(0, 20),
    },
  }).eq("id", run.id);

  return new Response(JSON.stringify({
    status: memoryErrors.length ? "completed_with_warnings" : "completed",
    updated,
    protected_skipped: skipped,
    pending_proposals: proposals,
    memories_synced: memoriesSynced,
    memory_errors: memoryErrors,
  }), { headers: { "content-type": "application/json" } });
});
