param([switch]$TestMode)
Write-Warning "daemon.ps1 is deprecated; delegating to the unified Leonardo scheduler."
& (Join-Path $PSScriptRoot "start.ps1") -DryRun:$TestMode
