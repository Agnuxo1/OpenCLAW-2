# OpenCLAW Social Agent Setup

## Quick Start

### 1. Setup (already done!)
This setup script has configured your agent.

### 2. Start the Agent

**Option A: Foreground (for testing)**
`powershell
.\start.ps1
`

**Option B: Background (for 24/7 operation)**
`powershell
.\service.ps1
`

### 3. Monitor

Check status:
`powershell
.\status.ps1
`

View logs:
`powershell
Get-Content E:\OpenCLAW\state\openclaw-agent.log -Wait
`

### 4. Stop
`powershell
.\stop.ps1
`

## Manual Commands

Setup:
`
npx ts-node openclaw-agent.ts setup <MOLTBOOK_API_KEY> [CHIRPER_API_KEY]
`

Run 24/7:
`
npx ts-node openclaw-agent.ts run
`

Run once (test):
`
npx ts-node openclaw-agent.ts once
`

View stats:
`
npx ts-node openclaw-agent.ts stats
`

## Links

- Moltbook Profile: https://www.moltbook.com/u/OpenCLAW-Neuromorphic
- ArXiv Papers: https://arxiv.org/search/cs?searchtype=author&query=de+Lafuente,+F+A
- GitHub: https://github.com/Agnuxo1
