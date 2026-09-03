import * as crypto from "crypto";
import * as path from "path";
import { externalActionsAllowed, runtimeConfig } from "./config";
import { RiskLevel } from "./contracts";
import { readJson, writeJsonAtomic } from "./state-store";

export type ApprovalStatus = "pending" | "approved" | "rejected" | "executed";

export interface ApprovalRequest {
  id: string;
  idempotencyKey: string;
  action: string;
  risk: RiskLevel;
  payload: Record<string, unknown>;
  status: ApprovalStatus;
  createdAt: string;
  updatedAt: string;
}

const approvalPath = path.join(runtimeConfig.stateDir, "approvals.json");

function load(): ApprovalRequest[] {
  return readJson<ApprovalRequest[]>(approvalPath, []);
}

function save(requests: ApprovalRequest[]): void {
  writeJsonAtomic(approvalPath, requests.slice(-1_000));
}

export function createIdempotencyKey(action: string, payload: Record<string, unknown>): string {
  return crypto.createHash("sha256").update(`${action}:${JSON.stringify(payload)}`).digest("hex");
}

export function requestApproval(
  action: string,
  risk: RiskLevel,
  payload: Record<string, unknown>,
): { allowed: boolean; request: ApprovalRequest } {
  const requests = load();
  const idempotencyKey = createIdempotencyKey(action, payload);
  const existing = requests.find((request) => request.idempotencyKey === idempotencyKey);

  if (existing) {
    return {
      allowed:
        externalActionsAllowed() &&
        (runtimeConfig.approvalMode === "auto" || existing.status === "approved"),
      request: existing,
    };
  }

  const now = new Date().toISOString();
  const request: ApprovalRequest = {
    id: `approval-${idempotencyKey.slice(0, 16)}`,
    idempotencyKey,
    action,
    risk,
    payload,
    status: runtimeConfig.approvalMode === "auto" ? "approved" : "pending",
    createdAt: now,
    updatedAt: now,
  };
  requests.push(request);
  save(requests);
  return { allowed: externalActionsAllowed() && request.status === "approved", request };
}

export function listApprovals(): ApprovalRequest[] {
  return load();
}

export function setApprovalStatus(id: string, status: ApprovalStatus): ApprovalRequest {
  const requests = load();
  const request = requests.find((entry) => entry.id === id);
  if (!request) throw new Error(`Approval request not found: ${id}`);
  request.status = status;
  request.updatedAt = new Date().toISOString();
  save(requests);
  return request;
}

export function markExecuted(id: string): void {
  setApprovalStatus(id, "executed");
}
