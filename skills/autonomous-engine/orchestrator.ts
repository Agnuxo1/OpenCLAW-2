import * as path from "path";
import { appendJsonRecord } from "./state-store";
import { runtimeConfig } from "./config";
import { ActionOutcome, AgentRole, Evidence, TaskContract } from "./contracts";
import { MemoryStore } from "./memory-store";

export interface SpecialistResult {
  output: Record<string, unknown>;
  evidence: Evidence[];
  summary: string;
}

export type Specialist = (
  task: TaskContract,
  context: { prior: SpecialistResult[]; memories: ReturnType<MemoryStore["relevant"]> },
) => Promise<SpecialistResult>;

export interface PipelineStep {
  role: Exclude<AgentRole, "leonardo">;
  specialist: Specialist;
}

export class LeonardoOrchestrator {
  private readonly memory = new MemoryStore();
  private readonly auditPath = path.join(runtimeConfig.stateDir, "orchestrator-audit.json");

  async run(task: TaskContract, steps: PipelineStep[]): Promise<ActionOutcome<SpecialistResult[]>> {
    if (Date.parse(task.deadline) <= Date.now()) {
      return { status: "failed", attempted: false, message: "Task deadline has expired" };
    }
    if (steps.length > task.budget.maxActions) {
      return { status: "failed", attempted: false, message: "Pipeline exceeds task action budget" };
    }

    const results: SpecialistResult[] = [];
    const memories = this.memory.relevant(task);
    try {
      for (const step of steps) {
        if (step.role === "publisher") {
          const evidenceCount = results.flatMap((result) => result.evidence).length;
          if (evidenceCount < task.requiredEvidence) {
            throw new Error(
              `Publisher blocked: ${evidenceCount}/${task.requiredEvidence} required evidence items`,
            );
          }
        }

        const result = await step.specialist(task, { prior: results, memories });
        results.push(result);
        this.memory.remember({
          kind: "episodic",
          taskId: task.id,
          role: step.role,
          content: result.summary,
          evidence: result.evidence,
          outcome: "success",
        });
        appendJsonRecord(this.auditPath, {
          taskId: task.id,
          role: step.role,
          summary: result.summary,
          evidenceCount: result.evidence.length,
          timestamp: new Date().toISOString(),
        });
      }
      return { status: "confirmed", attempted: true, message: "Pipeline completed", data: results };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.memory.remember({
        kind: "episodic",
        taskId: task.id,
        role: "leonardo",
        content: message,
        evidence: [],
        outcome: "failure",
      });
      return { status: "failed", attempted: true, message, error: message };
    }
  }
}
