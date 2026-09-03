#!/usr/bin/env node
import * as fs from "fs";
import * as path from "path";
import { runtimeConfig, setForceDryRun } from "./config";
import { ActionOutcome, isConfirmed } from "./contracts";
import { runLiteraryCycle } from "./literary-tasks";
import { SingleFlight } from "./reliability";
import {
  ArxivPaper,
  getCollaborationPost,
  getPostContentForPaper,
  getResearchProfile,
} from "./research-scraper";
import {
  getRecentActivity,
  getStats,
  initPlatforms,
  postToChirper,
  postToMoltbook,
  proactiveEngagement,
} from "./social-connector";
import { readJson, writeJsonAtomic } from "./state-store";

const logPath = path.join(runtimeConfig.stateDir, "openclaw-agent.log");
const statePath = path.join(runtimeConfig.stateDir, "agent_state.json");
const learningPath = path.join(runtimeConfig.stateDir, "learnings.json");
const singleFlight = new SingleFlight();

const researchTopics = [
  "neuromorphic",
  "holographic",
  "ASIC",
  "AGI",
  "neural network",
  "reservoir computing",
  "thermodynamic",
  "machine learning",
  "healthcare",
  "hardware acceleration",
];

interface Metrics {
  planned: number;
  attempted: number;
  confirmed: number;
  queued: number;
  skipped: number;
  failed: number;
}

interface AgentState {
  lastPostAttempt: string | null;
  lastPostConfirmed: string | null;
  lastEngagementAttempt: string | null;
  lastCollaborationAttempt: string | null;
  cycle: number;
  startTime: string;
  papersShared: string[];
  errors: Array<{ timestamp: string; action: string; message: string }>;
  metrics: Metrics;
  strategy: {
    postIntervalHours: number;
    engagementIntervalMinutes: number;
    consecutiveFailures: number;
    pausedUntil: string | null;
  };
}

function log(message: string, level: "INFO" | "SUCCESS" | "ERROR" | "WARN" = "INFO"): void {
  const line = `[${new Date().toISOString()}] [${level}] ${message}`;
  console.log(line);
  fs.mkdirSync(runtimeConfig.stateDir, { recursive: true });
  fs.appendFileSync(logPath, `${line}\n`, "utf8");
}

function initialState(): AgentState {
  return {
    lastPostAttempt: null,
    lastPostConfirmed: null,
    lastEngagementAttempt: null,
    lastCollaborationAttempt: null,
    cycle: 0,
    startTime: new Date().toISOString(),
    papersShared: [],
    errors: [],
    metrics: { planned: 0, attempted: 0, confirmed: 0, queued: 0, skipped: 0, failed: 0 },
    strategy: {
      postIntervalHours: 4,
      engagementIntervalMinutes: 60,
      consecutiveFailures: 0,
      pausedUntil: null,
    },
  };
}

function loadState(): AgentState {
  const stored = readJson<Partial<AgentState>>(statePath, {});
  const base = initialState();
  return {
    ...base,
    ...stored,
    metrics: { ...base.metrics, ...stored.metrics },
    strategy: { ...base.strategy, ...stored.strategy },
    errors: Array.isArray(stored.errors) ? stored.errors : [],
    papersShared: Array.isArray(stored.papersShared) ? stored.papersShared : [],
  };
}

function saveState(state: AgentState): void {
  state.errors = state.errors.slice(-100);
  writeJsonAtomic(statePath, state);
}

function shouldRun(lastRun: string | null, intervalMs: number): boolean {
  return !lastRun || Date.now() - Date.parse(lastRun) >= intervalMs;
}

function record<T>(state: AgentState, action: string, outcome: ActionOutcome<T>): void {
  state.metrics.planned += 1;
  if (outcome.attempted) state.metrics.attempted += 1;
  state.metrics[outcome.status] += 1;
  if (outcome.status === "failed") {
    state.strategy.consecutiveFailures += 1;
    state.errors.push({ timestamp: new Date().toISOString(), action, message: outcome.message });
    log(`${action}: ${outcome.message}`, "ERROR");
  } else {
    if (outcome.status === "confirmed") state.strategy.consecutiveFailures = 0;
    log(`${action}: ${outcome.message}`, outcome.status === "confirmed" ? "SUCCESS" : "INFO");
  }

  if (state.strategy.consecutiveFailures >= 3) {
    state.strategy.pausedUntil = new Date(Date.now() + 30 * 60_000).toISOString();
    log("Circuit opened after three consecutive failures; external work paused for 30 minutes", "WARN");
  }
}

function paused(state: AgentState): boolean {
  if (!state.strategy.pausedUntil) return false;
  if (Date.parse(state.strategy.pausedUntil) <= Date.now()) {
    state.strategy.pausedUntil = null;
    state.strategy.consecutiveFailures = 0;
    return false;
  }
  return true;
}

async function postResearch(state: AgentState): Promise<void> {
  state.lastPostAttempt = new Date().toISOString();
  try {
    const profile = await getResearchProfile();
    const candidates = profile.papers.filter((paper) => !state.papersShared.includes(paper.id));
    const paper: ArxivPaper | undefined = candidates[0];
    if (!paper) {
      record(state, "research.post", {
        status: "skipped",
        attempted: false,
        message: "No new verified paper available",
      });
      return;
    }
    const outcome = await postToMoltbook(
      `[ArXiv] ${paper.title}`,
      getPostContentForPaper(paper, "moltbook"),
      "general",
    );
    record(state, "research.post", outcome);
    if (isConfirmed(outcome)) {
      state.papersShared.push(paper.id);
      state.lastPostConfirmed = new Date().toISOString();
      record(
        state,
        "chirper.queue",
        await postToChirper(getPostContentForPaper(paper, "chirper"), paper.primary_category),
      );
    }
  } catch (error) {
    record(state, "research.fetch", {
      status: "failed",
      attempted: true,
      message: error instanceof Error ? error.message : String(error),
    });
  }
}

async function engage(state: AgentState): Promise<void> {
  state.lastEngagementAttempt = new Date().toISOString();
  record(state, "community.engage", await proactiveEngagement(researchTopics));
}

async function collaborate(state: AgentState): Promise<void> {
  state.lastCollaborationAttempt = new Date().toISOString();
  const invitation = getCollaborationPost();
  record(
    state,
    "collaboration.post",
    await postToMoltbook(invitation.title, invitation.content, "general"),
  );
}

function selfImprove(state: AgentState): void {
  const recent = getRecentActivity(24);
  if (recent.posts.length === 0 && state.metrics.failed > 0) {
    state.strategy.postIntervalHours = Math.min(24, state.strategy.postIntervalHours * 2);
  } else if (recent.posts.length > 0) {
    state.strategy.postIntervalHours = 4;
  }
  if (recent.engagements.length === 0) {
    state.strategy.engagementIntervalMinutes = Math.min(240, state.strategy.engagementIntervalMinutes + 30);
  } else {
    state.strategy.engagementIntervalMinutes = 60;
  }
  const learning = {
    timestamp: new Date().toISOString(),
    confirmedPosts24h: recent.posts.length,
    confirmedEngagements24h: recent.engagements.length,
    strategy: state.strategy,
    metrics: state.metrics,
  };
  const learnings = readJson<typeof learning[]>(learningPath, []);
  writeJsonAtomic(learningPath, [...learnings, learning].slice(-100));
  log(`Strategy updated from confirmed outcomes: ${JSON.stringify(state.strategy)}`);
}

async function heartbeat(state: AgentState): Promise<void> {
  state.cycle += 1;
  log(`Heartbeat #${state.cycle}`);
  if (paused(state)) {
    log(`External work paused until ${state.strategy.pausedUntil}`, "WARN");
    saveState(state);
    return;
  }

  if (shouldRun(state.lastPostAttempt, state.strategy.postIntervalHours * 60 * 60_000)) {
    await postResearch(state);
  }
  if (
    shouldRun(state.lastEngagementAttempt, state.strategy.engagementIntervalMinutes * 60_000)
  ) {
    await engage(state);
  }
  if (shouldRun(state.lastCollaborationAttempt, 12 * 60 * 60_000)) await collaborate(state);
  record(state, "literary.pipeline", await runLiteraryCycle(state.cycle));
  if (state.cycle % 6 === 0) selfImprove(state);
  saveState(state);
}

async function runOnce(state: AgentState): Promise<void> {
  const result = await singleFlight.run(() => heartbeat(state));
  if (result === undefined) log("Skipped overlapping heartbeat", "WARN");
}

export async function runAgentOnce(options: { dryRun?: boolean } = {}): Promise<void> {
  setForceDryRun(options.dryRun ?? true);
  initPlatforms();
  await runOnce(loadState());
}

export function getAgentStatus(): unknown {
  return { state: loadState(), confirmed: getStats() };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args.find((arg) => !arg.startsWith("--")) || "help";
  setForceDryRun(args.includes("--dry-run"));
  initPlatforms();
  const state = loadState();

  if (command === "once") {
    await runOnce(state);
    return;
  }
  if (command === "run") {
    await runOnce(state);
    setInterval(() => void runOnce(state), runtimeConfig.heartbeatMinutes * 60_000);
    return;
  }
  if (command === "stats" || command === "status") {
    console.log(JSON.stringify({ state, confirmed: getStats() }, null, 2));
    return;
  }
  console.log("Usage: openclaw-agent.ts run|once [--dry-run]|stats|status");
}

if (require.main === module) {
  main().catch((error) => {
    log(`Fatal error: ${error instanceof Error ? error.message : String(error)}`, "ERROR");
    process.exitCode = 1;
  });
}
