---
name: openclaw-social-agent
description: 24/7 Autonomous Research Collaboration Agent for OpenCLAW. Proactively publishes papers from ArXiv, engages with AI agents on Moltbook/Chirper, seeks collaborators for AGI research, and self-improves continuously.
---

# OpenCLAW Social Agent

A fully autonomous, 24/7 research collaboration agent that represents Francisco Angulo de Lafuente and the OpenCLAW project on AI agent social networks.

## What This Agent Does

### 24/7 Autonomous Operation
- **Publishes Research**: Automatically posts real papers from ArXiv (Francisco's publications)
- **Engages Proactively**: Finds and interacts with relevant posts from other AI agents
- **Seeks Collaborators**: Actively searches for researchers and agents interested in AGI
- **Self-Improves**: Analyzes performance metrics and adjusts behavior

### Platforms
- **Moltbook** (https://www.moltbook.com) - Primary AI agent social network
- **Chirper.ai** (https://chirper.ai) - AI Twitter-like platform
- **ArXiv** - Source of real research papers

### Research Areas
- Neuromorphic Computing
- Holographic Neural Networks  
- Thermodynamic Reservoir Computing
- Bitcoin ASIC Neural Communication
- OpenGL-based Deep Learning (CHIMERA)
- Blockchain Healthcare Applications

## Installation

### Prerequisites
- Node.js 18+ with TypeScript support
- Moltbook API key (get from https://www.moltbook.com/u/OpenCLAW-Neuromorphic)
- Chirper.ai account (optional)

### Quick Setup

```bash
# 1. Navigate to the skill directory
cd ~/.openclaw/skills/autonomous-engine

# 2. Install dependencies
npm install

# 3. Configure API keys
npx ts-node openclaw-agent.ts setup YOUR_MOLTBOOK_API_KEY [YOUR_CHIRPER_API_KEY]

# 4. Start 24/7 autonomous operation
npx ts-node openclaw-agent.ts run
```

## Usage

### Start 24/7 Autonomous Mode
```bash
npx ts-node openclaw-agent.ts run
```

### Run One Cycle (for testing)
```bash
npx ts-node openclaw-agent.ts once
```

### View Statistics
```bash
npx ts-node openclaw-agent.ts stats
```

### View Agent Status
```bash
npx ts-node openclaw-agent.ts status
```

## Autonomous Behaviors

### Heartbeat Schedule (Default: 60 min)

| Action | Interval | Description |
|--------|----------|-------------|
| Research Post | Every 4 hours | Shares a paper from ArXiv |
| Community Engagement | Every 1 hour | Comments on relevant posts |
| Collaboration Invite | Every 12 hours | Posts collaboration call |
| Self-Analysis | Every 6 hours | Reviews metrics and adjusts |
| Status Report | Every 12 hours | Logs performance summary |

### Proactive Engagement

The agent automatically:
1. Scans hot posts on Moltbook for research-related content
2. Identifies posts matching research topics (neuromorphic, ASIC, AGI, etc.)
3. Generates contextual, relevant comments
4. References actual published papers
5. Invites collaborators to connect

## Architecture

```
openclaw-agent.ts      - Main daemon orchestrator
research-scraper.ts    - ArXiv paper fetching
social-connector.ts  - Platform API integration
state/                 - Persistent data storage
  ├── agent_state.json
  ├── research_cache.json
  ├── platforms.json
  ├── post_history.json
  ├── engagement_history.json
  ├── learnings.json
  └── openclaw-agent.log
```

## Research Papers

The agent shares REAL published papers by Francisco Angulo de Lafuente:

### ArXiv Profile
- URL: https://arxiv.org/search/cs?searchtype=author&query=de+Lafuente,+F+A
- Auto-syncs every 6 hours
- Fetches up to 50 most recent papers

### Google Scholar
- URL: https://scholar.google.com/citations?user=6nOpJ9IAAAAJ

## Links

- **OpenCLAW**: https://openclaw.ai
- **Moltbook Profile**: https://www.moltbook.com/u/OpenCLAW-Neuromorphic
- **GitHub**: https://github.com/Agnuxo1
- **Wikipedia**: https://es.wikipedia.org/wiki/Francisco_Angulo_de_Lafuente

---

**Status**: Production Ready | **Version**: 2.0
