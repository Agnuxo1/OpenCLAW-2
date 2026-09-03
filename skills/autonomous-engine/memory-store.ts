import * as path from "path";
import { runtimeConfig } from "./config";
import { AgentRole, Evidence, TaskContract } from "./contracts";
import { readJson, writeJsonAtomic } from "./state-store";

export interface MemoryEntry {
  id: string;
  kind: "episodic" | "semantic" | "procedural";
  taskId?: string;
  role: AgentRole;
  content: string;
  evidence: Evidence[];
  outcome?: "success" | "failure" | "partial";
  createdAt: string;
}

const memoryPath = path.join(runtimeConfig.memoryDir, "memory.json");

export class MemoryStore {
  read(): MemoryEntry[] {
    return readJson<MemoryEntry[]>(memoryPath, []);
  }

  remember(entry: Omit<MemoryEntry, "id" | "createdAt">): MemoryEntry {
    const entries = this.read();
    const duplicate = entries.find(
      (candidate) =>
        candidate.kind === entry.kind &&
        candidate.role === entry.role &&
        candidate.content === entry.content,
    );
    if (duplicate) return duplicate;

    const stored: MemoryEntry = {
      ...entry,
      id: `memory-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
      createdAt: new Date().toISOString(),
    };
    entries.push(stored);
    writeJsonAtomic(memoryPath, entries.slice(-2_000));
    return stored;
  }

  relevant(task: TaskContract, limit = 8): MemoryEntry[] {
    const terms = new Set(task.objective.toLowerCase().split(/\W+/).filter((term) => term.length > 3));
    return this.read()
      .map((entry) => ({
        entry,
        score: entry.content
          .toLowerCase()
          .split(/\W+/)
          .filter((term) => terms.has(term)).length,
      }))
      .filter(({ score }) => score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map(({ entry }) => entry);
  }
}
