import * as path from "path";

function envBoolean(name: string, fallback: boolean): boolean {
  const value = process.env[name]?.trim().toLowerCase();
  if (!value) return fallback;
  return value === "1" || value === "true" || value === "yes";
}

function envNumber(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

const repoRoot = path.resolve(__dirname, "..", "..");

export const runtimeConfig = {
  repoRoot,
  stateDir: path.resolve(
    process.env.OPENCLAW_STATE_DIR?.trim() || path.join(repoRoot, ".local", "autonomous-engine"),
  ),
  memoryDir: path.resolve(
    process.env.OPENCLAW_MEMORY_DIR?.trim() || path.join(repoRoot, ".local", "autonomous-engine", "memory"),
  ),
  heartbeatMinutes: envNumber("OPENCLAW_HEARTBEAT_MINUTES", 30),
  httpTimeoutMs: envNumber("OPENCLAW_HTTP_TIMEOUT_MS", 15_000),
  externalActionsEnabled: envBoolean("OPENCLAW_EXTERNAL_ACTIONS", false),
  approvalMode: process.env.OPENCLAW_APPROVAL_MODE === "auto" ? "auto" : "required",
  moltbookApiBase: process.env.MOLTBOOK_API_BASE?.trim() || "https://www.moltbook.com/api/v1",
  moltbookApiKey: process.env.MOLTBOOK_API_KEY?.trim() || "",
  chirperApiKey: process.env.CHIRPER_API_KEY?.trim() || "",
  llmEndpoint: process.env.OPENCLAW_LLM_ENDPOINT?.trim() || "http://127.0.0.1:8081/v1/chat/completions",
  llmModel: process.env.OPENCLAW_LLM_MODEL?.trim() || "local/glm-4.7-flash",
} as const;

let forceDryRun = false;

export function setForceDryRun(value: boolean): void {
  forceDryRun = value;
}

export function externalActionsAllowed(): boolean {
  return runtimeConfig.externalActionsEnabled && !forceDryRun;
}

export function requireSecret(name: string, value: string): string {
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}
