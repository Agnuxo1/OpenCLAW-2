# OpenCLAW Social Agent - Background Service
# Run this to start the agent in background

$proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"E:\OpenCLAW-2\skills\autonomous-engine\start.ps1`"" -PassThru
Write-Host "OpenCLAW Agent started as process ID: $($proc.Id)"
Write-Host "Log file: E:\OpenCLAW-2\state\openclaw-agent.log"
$proc.Id | Set-Content "E:\OpenCLAW-2\state\agent.pid"
