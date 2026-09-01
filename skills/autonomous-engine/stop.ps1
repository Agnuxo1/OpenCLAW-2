$ErrorActionPreference = "Stop"
$stateDir = if ($env:OPENCLAW_STATE_DIR) { $env:OPENCLAW_STATE_DIR } else { Join-Path (Split-Path (Split-Path $PSScriptRoot)) ".local\autonomous-engine" }
$pidPath = Join-Path $stateDir "agent.pid"
if (-not (Test-Path -LiteralPath $pidPath)) {
    Write-Host "No managed Leonardo process is registered."
    exit 0
}
$agentPid = [int](Get-Content -LiteralPath $pidPath -Raw)
$process = Get-Process -Id $agentPid -ErrorAction SilentlyContinue
if ($process) { Stop-Process -Id $agentPid }
Remove-Item -LiteralPath $pidPath
Write-Host "Leonardo process $agentPid stopped."
