# Project: OpenCLAW-2
# Copyright (c) 2026 Francisco Angulo de Lafuente
# Author: Francisco Angulo de Lafuente
# ORCID: https://orcid.org/0009-0001-1634-7063
# Attribution recorded: 2026-11-05
# SPDX-License-Identifier: MIT

# OpenCLAW Social Agent - Stop Script

if (Test-Path "E:\OpenCLAW-2\state\agent.pid") {
    $pid_val = Get-Content "E:\OpenCLAW-2\state\agent.pid"
    try {
        Stop-Process -Id $pid_val -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped agent process $pid_val" -ForegroundColor Green
        Remove-Item "E:\OpenCLAW-2\state\agent.pid" -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Could not stop process $($pid_val), may already be stopped" -ForegroundColor Yellow
    }
}
else {
    # Try to find by process name
    $procs = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "openclaw-agent" }
    if ($procs) {
        $procs | ForEach-Object { 
            Stop-Process -Id $_.Id -Force
            Write-Host "Stopped process $($_.Id)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "No agent process found" -ForegroundColor Yellow
    }
}
