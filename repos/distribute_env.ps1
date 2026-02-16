$source = "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary2\.env"
$destinations = @(
    "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform",
    "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary",
    "E:\OpenCLAW-4\repos\OpenCLAW-2-Literary-Agent",
    "E:\OpenCLAW-4\repos\OpenCLAW-2-moltbook-Agent",
    "E:\OpenCLAW-4\repos\OpenCLAW-2",
    "E:\OpenCLAW-4\repos\OpenCLAW-Autonomous-Multi-Agent-Scientific-Research-Platform",
    "E:\OpenCLAW-4\repos\OpenCLAW-update-Literary-Agent-24-7-auto"
)

foreach ($dest in $destinations) {
    if (Test-Path $dest) {
        Copy-Item -Path $source -Destination "$dest\.env" -Force
        Write-Host "Copied .env to $dest"
    } else {
        Write-Warning "Directory not found: $dest"
    }
}
