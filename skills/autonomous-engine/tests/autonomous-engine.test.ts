import * as assert from "node:assert/strict";
import { test } from "node:test";
import { createTask } from "../contracts";
import { setForceDryRun } from "../config";
import { LeonardoOrchestrator } from "../orchestrator";
import { CircuitBreaker, SingleFlight } from "../reliability";
import { postToMoltbook } from "../social-connector";

test("task contracts receive bounded defaults", () => {
  const task = createTask({
    objective: "Verify a claim",
    input: {},
    assignedRole: "leonardo",
    risk: "medium",
    requiredEvidence: 1,
    allowedTools: ["catalog.read"],
  });
  assert.match(task.id, /^task-/);
  assert.equal(task.budget.maxActions, 8);
  assert.ok(Date.parse(task.deadline) > Date.now());
});

test("Leonardo blocks publishing without enough evidence", async () => {
  const task = createTask({
    objective: "Publish a verified note",
    input: {},
    assignedRole: "leonardo",
    risk: "high",
    requiredEvidence: 1,
    allowedTools: ["publisher"],
  });
  const outcome = await new LeonardoOrchestrator().run(task, [
    {
      role: "writer",
      specialist: async () => ({ output: { content: "draft" }, evidence: [], summary: "drafted" }),
    },
    {
      role: "publisher",
      specialist: async () => {
        throw new Error("publisher should never execute");
      },
    },
  ]);
  assert.equal(outcome.status, "failed");
  assert.match(outcome.message, /required evidence/);
});

test("single-flight prevents overlapping agent cycles", async () => {
  const gate = new SingleFlight();
  let release: (() => void) | undefined;
  const first = gate.run(
    () => new Promise<void>((resolve) => {
      release = resolve;
    }),
  );
  const second = await gate.run(async () => "unexpected");
  assert.equal(second, undefined);
  release?.();
  await first;
});

test("circuit breaker opens and recovers after cooldown", () => {
  const breaker = new CircuitBreaker(2, 10);
  breaker.failure();
  assert.equal(breaker.canRun(0), true);
  breaker.failure();
  assert.equal(breaker.canRun(Date.now()), false);
  assert.equal(breaker.canRun(Date.now() + 20), true);
  breaker.success();
  assert.equal(breaker.canRun(Date.now()), true);
});

test("dry-run queues publication without contacting the provider", async () => {
  setForceDryRun(true);
  const outcome = await postToMoltbook(
    `Test title ${Date.now()}`,
    "This test payload must only enter the local approval queue.",
    "tests",
  );
  assert.equal(outcome.status, "queued");
  assert.equal(outcome.attempted, false);
});
