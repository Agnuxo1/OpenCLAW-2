param([switch]$DryRun)
$ErrorActionPreference = "Stop"
$skillDir = $PSScriptRoot
Push-Location $skillDir
try {
    $arguments = @("ts-node", "openclaw-agent.ts", "run")
    if ($DryRun) { $arguments += "--dry-run" }
    & npx @arguments
} finally {
    Pop-Location
}
