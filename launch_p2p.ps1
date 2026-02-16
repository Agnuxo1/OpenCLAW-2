# OpenCLAW-P2P Launch Script
# Initializing the global decentralized path toward AGI/ASI

$repoPath = "E:\OpenCLAW-P2P-Launch"
if (!(Test-Path $repoPath)) { New-Item -ItemType Directory -Path $repoPath }

Set-Location $repoPath

# 1. Structure
New-Item -ItemType Directory -Path "$repoPath\core" -Force
New-Item -ItemType Directory -Path "$repoPath\skills" -Force
New-Item -ItemType Directory -Path "$repoPath\docs" -Force
New-Item -ItemType Directory -Path "$repoPath\ui" -Force

# 2. Copy Files (Source: E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary2)
$sourcePath = "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary2"

Copy-Item "$sourcePath\core\p2p_manager.py" "$repoPath\core\"
Copy-Item "$sourcePath\core\torrent_manager.py" "$repoPath\core\"
Copy-Item "$sourcePath\skills\p2p_skill.py" "$repoPath\skills\"
Copy-Item "$sourcePath\docs\agi_paper.md" "$repoPath\docs\"
Copy-Item "$sourcePath\ui\p2p_dashboard\index.html" "$repoPath\ui\"

# 3. Create README
$readmeContent = @"
# OpenCLAW-P2P: Decentralized AGI/ASI Infrastructure

OpenCLAW-P2P is a collective intelligence framework that unifies global computing resources and agentic cognition.

## Core Pillars
- **HiveMind**: Decentralized agent discovery and knowledge exchange (via GitHub Gists).
- **BitTorrent**: Distributed data and compute exchange (via uTorrent Web).
- **Collective Intelligence**: Swarm-based research and self-improvement loops.

## Deployment
1. Set `GITHUB_TOKEN` and `HIVEMIND_GIST_ID` in your `.env`.
2. Start your local OpenCLAW node.
3. Access the P2P Dashboard via `/ui/index.html`.

---
*Unifying intelligence for the future of humanity.*
"@
$readmeContent | Out-File -FilePath "$repoPath\README.md" -Encoding utf8

# 4. Git Initialization & Push
git init
git add .
git commit -m "Initial Launch: OpenCLAW-P2P Global Protocol v1.0"
git remote add origin https://github.com/Agnuxo1/OpenCLAW-P2P
git branch -M main
# Note: Pushing will require user credentials if not cached
Write-Host "✅ Repository prepared at $repoPath"
Write-Host "🚀 READY TO LAUNCH: git push -u origin main"
