param([switch]$DryRun)
$ErrorActionPreference = "Stop"
$stateDir = if ($env:OPENCLAW_STATE_DIR) { $env:OPENCLAW_STATE_DIR } else { Join-Path (Split-Path (Split-Path $PSScriptRoot)) ".local\autonomous-engine" }
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "start.ps1"))
if ($DryRun) { $arguments += "-DryRun" }
$proc = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -WindowStyle Hidden -PassThru
$proc.Id | Set-Content -LiteralPath (Join-Path $stateDir "agent.pid")
Write-Host "Leonardo started as process $($proc.Id). State: $stateDir"
