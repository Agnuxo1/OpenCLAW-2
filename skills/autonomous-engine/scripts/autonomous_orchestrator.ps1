# autonomous_orchestrator.ps1
# OpenCLAW Global Task Orchestrator
# Runs brain scripts, interacts with AI agent platforms, and takes real-world action.
# 24/7 Autonomous Operation for AGI Research Collaboration

$ScriptRoot = $PSScriptRoot
$BrainScriptsDir = "E:\OpenCLAW\workspace\scripts"
$AgentArxivProject = "E:\OpenCLAW\skills\agentarxiv\scripts\research_scheduler.ps1"
$RedditProject = "E:\OpenCLAW\skills\reddit-automator\scripts\reddit_scheduler.ps1"
$XingProject = "E:\OpenCLAW\skills\xing-automator\scripts\xing_scheduler.ps1"
$GitHubProject = Join-Path $ScriptRoot "github_collaborator.ps1"
$AgentDaemon = "E:\OpenCLAW\skills\autonomous-engine\daemon.ps1"
$LogFile = "E:\OpenCLAW\state\autonomous_engine.log"
$StateDir = "E:\OpenCLAW\state"

function Log-Activity {
    param([string]$Message, [string]$Color = "Green")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [ORCHESTRATOR] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $line
}

Log-Activity "Initializing Global Orchestration Loop..." -Color Cyan

while ($true) {
    try {
        # --- PHASE 1: Internal Cognition (Brain Scripts) ---
        Log-Activity "Step 1: Running Brain Scripts (Self-Improvement & Strategy)..."
        $scripts = Get-ChildItem -Path $BrainScriptsDir -Filter "*.js"
        foreach ($script in $scripts) {
            Log-Activity "  Executing: $($script.Name)"
            node $script.FullName | Out-Null
            Start-Sleep -Seconds 2
        }

        # --- PHASE 2: Proactive Collaboration (GitHub) ---
        Log-Activity "Step 2: Proactive GitHub Outreach..."
        powershell -NoProfile -File $GitHubProject -DryRun $false | Out-Null

        # --- PHASE 3: Community Engagement (Arxiv Feed) ---
        # The research_scheduler already does this, but we ensure it's healthy
        Log-Activity "Step 3: Checking external schedulers (Reddit/XING/Arxiv)..."
        $procs = Get-Process | Where-Object { $_.CommandLine -match "scheduler" }
        Log-Activity "  Active schedulers: $($procs.Count)"

        # --- PHASE 4: AI Agent Platform Interaction ---
        Log-Activity "Step 4: Interacting with AI Agent Platforms (AgentArxiv, Moltbook)..."

        # Run the autonomous agent daemon for one cycle
        if (Test-Path $AgentDaemon) {
            $daemonPid = "$StateDir\autonomous_daemon.pid"
            $daemonRunning = $false

            if (Test-Path $daemonPid) {
                $savedPid = Get-Content $daemonPid -ErrorAction SilentlyContinue
                if ($savedPid) {
                    $proc = Get-Process -Id $savedPid -ErrorAction SilentlyContinue
                    if ($proc) { $daemonRunning = $true }
                }
            }

            if (-not $daemonRunning) {
                Log-Activity "  Starting Agent Platform Daemon..."
                $proc = Start-Process powershell -ArgumentList "-NoProfile -File `"$AgentDaemon`"" -WindowStyle Hidden -PassThru
                if ($proc) {
                    $proc.Id | Set-Content $daemonPid
                    Log-Activity "  Daemon started (PID: $($proc.Id))" -Color Green
                }
            } else {
                Log-Activity "  Agent Daemon already running (PID: $savedPid)" -Color Green
            }
        }

        # --- PHASE 5: Strategic Action (Self-Correction) ---
        Log-Activity "Step 5: Analyzing Cognitive Reports..."
        $reports = Get-ChildItem -Path "E:\OpenCLAW\workspace" -Filter "*-report.json" -ErrorAction SilentlyContinue
        if ($reports) {
            Log-Activity "  Found $($reports.Count) cognitive reports"
        }

        Log-Activity "Orchestration cycle complete. Next cycle in 1 hour."

    }
    catch {
        Log-Activity "Orchestrator Error: $($_.Exception.Message)" -Color Red
    }
    
    Start-Sleep -Seconds 3600 # Run every hour
}
