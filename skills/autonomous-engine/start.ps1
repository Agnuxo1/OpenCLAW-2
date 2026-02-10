# OpenCLAW Social Agent - Start Script
# Run this to start the 24/7 autonomous agent

cd "E:\OpenCLAW-2\skills\autonomous-engine"
Write-Host "Starting OpenCLAW Social Agent..." -ForegroundColor Green
Write-Host "Logs: E:\OpenCLAW-2\state\openclaw-agent.log" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""
npx ts-node openclaw-agent.ts run
