import { listApprovals, setApprovalStatus } from "./approval-store";

const [command = "list", id] = process.argv.slice(2);

if (command === "list") {
  const requests = listApprovals();
  console.table(
    requests.map(({ id: requestId, action, risk, status, createdAt }) => ({
      id: requestId,
      action,
      risk,
      status,
      createdAt,
    })),
  );
} else if ((command === "approve" || command === "reject") && id) {
  const request = setApprovalStatus(id, command === "approve" ? "approved" : "rejected");
  console.log(`${request.id}: ${request.status}`);
} else {
  console.error("Usage: npm run approvals -- list|approve <id>|reject <id>");
  process.exitCode = 1;
}
