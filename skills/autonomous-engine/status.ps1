$ErrorActionPreference = "Stop"
$stateDir = if ($env:OPENCLAW_STATE_DIR) { $env:OPENCLAW_STATE_DIR } else { Join-Path (Split-Path (Split-Path $PSScriptRoot)) ".local\autonomous-engine" }
$pidPath = Join-Path $stateDir "agent.pid"
$running = $false
if (Test-Path -LiteralPath $pidPath) {
    $agentPid = [int](Get-Content -LiteralPath $pidPath -Raw)
    $running = $null -ne (Get-Process -Id $agentPid -ErrorAction SilentlyContinue)
}
Write-Host "Leonardo running: $running"
Push-Location $PSScriptRoot
try { & npx ts-node openclaw-agent.ts status } finally { Pop-Location }
