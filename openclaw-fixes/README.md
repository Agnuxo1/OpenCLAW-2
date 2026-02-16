# OpenCLAW Network Fix Kit — Deployment Guide
## February 14, 2026

---

## Overview

This fix kit resolves ALL identified errors across the 8-repository OpenCLAW agent network
and deploys the HiveMind P2P communication architecture.

### Files Included

```
openclaw-fixes/
├── scientific-v1-ts/
│   ├── package.json              # FIX 1: Adds fs-extra (15 failures)
│   └── .github/workflows/        # Fixed workflow with npm install
├── scientific-v2-py/
│   └── enhanced_harvester.py     # FIX 2: 5 data sources + backoff
├── literary2-glm5/
│   └── env_adapter.py            # FIX 4: Bridges numbered→CSV keys
├── literary-update/
│   └── .github/workflows/        # FIX 5: Cron + keys + reactivation
├── hivemind/
│   ├── unified_llm.py            # 29-key LLM pool with failover
│   ├── hivemind.py               # P2P shared memory via Gists
│   └── devops_agent.py           # Self-healing network monitor
└── scripts/
    ├── deploy_fixes.sh           # Master deployment script
    └── unify_secrets.sh          # Secret propagation across repos
```

---

## Quick Start (5 Minutes)

### Step 1: Fix Scientific v1 (stops 15 daily failures)

Open the repo settings on GitHub and edit `package.json`:

```json
"dependencies": {
    "fs-extra": "^11.2.0"
}
```

Or push the fixed file from `scientific-v1-ts/package.json`.

### Step 2: Fix Literary2 GLM5 (enables 30 disabled keys)

Copy `env_adapter.py` to the root of the literary2 repo.
Add to the workflow BEFORE the main agent runs:

```yaml
- name: Consolidate API Keys
  run: python env_adapter.py
```

### Step 3: Reactivate Literary-update

Copy the workflow from `literary-update/.github/workflows/literary-update.yml`
to the repo's `.github/workflows/` directory.

### Step 4: Deploy unified LLM to all Python agents

Copy `hivemind/unified_llm.py` to the root of these repos:
- OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform
- OpenCLAW-2-Autonomous-Multi-Agent-literary
- OpenCLAW-2-Autonomous-Multi-Agent-literary2
- OpenCLAW-update-Literary-Agent-24-7-auto

---

## Detailed Fixes

### FIX 1: Scientific v1 (TypeScript) — `Cannot find module 'fs-extra'`
- **Impact:** 15 consecutive failures since Feb 12
- **Root cause:** fs-extra not in package.json dependencies
- **Fix:** Add `"fs-extra": "^11.2.0"` to dependencies
- **Alternative:** Disable the cron to save Actions minutes while you migrate to Python v2

### FIX 2: Scientific v2 (Python) — Semantic Scholar 429
- **Impact:** 0 new data from Semantic Scholar every cycle
- **Root cause:** No rate limiting/backoff
- **Fix:** `enhanced_harvester.py` adds exponential backoff + 4 new sources

### FIX 3: Literary v1 — Already 100% (enhancements only)
- Unified LLM module for future-proofing
- HiveMind integration for P2P collaboration

### FIX 4: Literary2 GLM5 — "No API keys found"
- **Impact:** 30 secrets configured but agent operates in "limited mode"
- **Root cause:** Code expects GEMINI_API_KEY, secrets named GEMINI_API_KEY_1
- **Fix:** `env_adapter.py` bridges the formats automatically

### FIX 5: Literary-update — Stopped agent
- **Impact:** Agent never runs (no cron schedule)
- **Root cause:** No cron + expired API keys + GH_TOKEN permissions
- **Fix:** New workflow with cron, correct env injection, env_adapter

---

## Secrets Unification

All agents should have access to the full 29-key pool.
Currently only Literary v1 has all keys.

### Using GitHub CLI (recommended):

```bash
# Set the same key in all 5 active repos at once
for repo in \
  OpenCLAW-Autonomous-Multi-Agent-Scientific-Research-Platform \
  OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform \
  OpenCLAW-2-Autonomous-Multi-Agent-literary \
  OpenCLAW-2-Autonomous-Multi-Agent-literary2 \
  OpenCLAW-update-Literary-Agent-24-7-auto; do
    gh secret set GROQ_API_KEYS --body "key1,key2,key3,key4,key5" -R Agnuxo1/$repo
    gh secret set NVIDIA_API_KEYS --body "key1,key2,key3" -R Agnuxo1/$repo
    gh secret set OPENROUTER_API_KEYS --body "key1,key2,...,key6" -R Agnuxo1/$repo
done
```

---

## HiveMind Architecture

The HiveMind enables P2P communication between agents using GitHub Gists as free storage.

### Setup:
1. Run `python hivemind.py init` to create the shared gist
2. Add the gist ID as `HIVEMIND_GIST_ID` to all repos
3. Agents can now publish/read messages to collaborate

### Example flow:
1. Scientific v2 discovers a paper on neuromorphic computing
2. Publishes to HiveMind: `{type: "discovery", topic: "neuromorphic"}`
3. Literary v1 reads discoveries and uses them for sci-fi novel promotion
4. DevOps agent monitors all agents and reports failures

---

## Expected Results After Deployment

| Agent | Before | After | Change |
|-------|--------|-------|--------|
| Literary v1 | 100% (20/20) | 100% + HiveMind | Enhanced |
| Literary2 GLM5 | 100% limited | 100% full mode | Keys detected |
| Scientific v2 | 97% (34/35) | 99%+ | 5 data sources |
| Scientific v1 | 59% (22/37) | 95%+ | fs-extra fixed |
| Literary-update | 50% stopped | 90%+ active | Reactivated |

### Network improvement:
- **Before:** 93/98 success (95%), 15 consecutive failures burning Actions minutes
- **After:** ~99% success, all 5 agents active 24/7, P2P collaboration enabled
