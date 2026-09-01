---
name: openclaw-autonomous-engine
description: Coordinate evidence-driven research and literary workflows through Leonardo, with specialist roles, durable memory, bounded execution, and approval-gated external publishing.
---

# OpenCLAW Autonomous Engine

Use Leonardo as the coordinator. Break work into explicit task contracts and route it through the smallest set of specialists needed:

- `researcher` gathers source-backed facts.
- `writer` drafts only from supplied facts.
- `verifier` blocks unsupported claims.
- `publisher` is the only role allowed to request an external mutation.
- `evaluator` records the confirmed outcome and useful learning.

Do not treat queued, skipped, or attempted actions as success. Only provider-confirmed actions count toward outcome metrics.

## Safety

External actions are disabled by default. They require both:

1. `OPENCLAW_EXTERNAL_ACTIONS=true` in the service environment.
2. An approved request from `npm run approvals -- approve <id>`, unless the operator explicitly configures `OPENCLAW_APPROVAL_MODE=auto`.

Never store credentials in prompts, JSON state, source files, CLI arguments, or logs. Configure the environment variables listed in `.env.example` through the service secret store.

Use `npm run once` for a dry run. Use `npm test` for isolated tests; it must not access live publishing or email APIs.

## Operation

```powershell
npm install
npm test
npm run build
npm run once
npm run approvals -- list
./start.ps1
```

Runtime state belongs in `OPENCLAW_STATE_DIR` or the ignored `.local/autonomous-engine` default. Catalog facts belong in `catalog.json` and require maintained source links. Do not invent performance data when confirmed metrics are unavailable; pause and diagnose the pipeline instead.
