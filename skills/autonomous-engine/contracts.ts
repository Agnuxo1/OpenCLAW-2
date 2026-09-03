export type AgentRole = "leonardo" | "researcher" | "verifier" | "writer" | "publisher" | "evaluator";
export type RiskLevel = "low" | "medium" | "high";
export type OutcomeStatus = "confirmed" | "queued" | "skipped" | "failed";

export interface Evidence {
  source: string;
  claim: string;
  verifiedAt: string;
}

export interface TaskContract {
  id: string;
  objective: string;
  input: Record<string, unknown>;
  assignedRole: AgentRole;
  risk: RiskLevel;
  deadline: string;
  budget: { maxActions: number; maxTokens: number };
  requiredEvidence: number;
  allowedTools: string[];
}

export interface ActionOutcome<T = unknown> {
  status: OutcomeStatus;
  attempted: boolean;
  message: string;
  data?: T;
  error?: string;
  retryable?: boolean;
}

export function isConfirmed<T>(outcome: ActionOutcome<T>): outcome is ActionOutcome<T> & { data: T } {
  return outcome.status === "confirmed" && outcome.data !== undefined;
}

export function createTask(
  task: Omit<TaskContract, "id" | "deadline" | "budget"> &
    Partial<Pick<TaskContract, "deadline" | "budget">>,
): TaskContract {
  return {
    ...task,
    id: `task-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`,
    deadline: task.deadline || new Date(Date.now() + 15 * 60_000).toISOString(),
    budget: task.budget || { maxActions: 8, maxTokens: 4_000 },
  };
}
