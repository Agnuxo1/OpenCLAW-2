#!/usr/bin/env node
import { getAgentStatus, runAgentOnce } from "./openclaw-agent";

async function main(): Promise<void> {
  const command = process.argv[2] || "once";
  console.warn("cognitive-agent.ts now delegates to the unified Leonardo orchestrator.");
  if (command === "stats" || command === "status") {
    console.log(JSON.stringify(getAgentStatus(), null, 2));
    return;
  }
  if (command !== "once") {
    throw new Error("Use openclaw-agent.ts run for the single production scheduler");
  }
  await runAgentOnce({ dryRun: true });
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
