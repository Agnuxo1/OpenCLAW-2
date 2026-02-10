# OpenCLAW Social Agent - Status Check

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "OpenCLAW Social Agent Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if running
$running = $false
if (Test-Path "E:\OpenCLAW-2\state\agent.pid") {
    $pid_val = Get-Content "E:\OpenCLAW-2\state\agent.pid"
    try {
        $proc = Get-Process -Id $pid_val -ErrorAction Stop
        $running = $true
        Write-Host "Status: RUNNING" -ForegroundColor Green
        Write-Host "Process ID: $pid_val" -ForegroundColor Green
        Write-Host "Start Time: $($proc.StartTime)" -ForegroundColor Green
    }
    catch {
        Write-Host "Status: STOPPED (stale PID file)" -ForegroundColor Red
        Remove-Item "E:\OpenCLAW-2\state\agent.pid" -ErrorAction SilentlyContinue
    }
}
else {
    # Check for node processes
    $procs = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "openclaw-agent" }
    if ($procs) {
        $running = $true
        Write-Host "Status: RUNNING (found node process)" -ForegroundColor Green
        $procs | ForEach-Object {
            Write-Host "Process $($_.Id): $($_.StartTime)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Status: STOPPED" -ForegroundColor Red
    }
}

# Show stats
cd "E:\OpenCLAW-2\skills\autonomous-engine"
npx ts-node openclaw-agent.ts stats

# Show recent log entries
if (Test-Path "E:\OpenCLAW-2\state\openclaw-agent.log") {
    Write-Host "`n--- Last 10 Log Entries ---" -ForegroundColor Yellow
    Get-Content "E:\OpenCLAW-2\state\openclaw-agent.log" -Tail 10
}

Write-Host "`n========================================" -ForegroundColor Cyan
