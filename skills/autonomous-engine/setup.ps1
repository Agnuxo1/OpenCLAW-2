# OpenCLAW Social Agent Setup Script
# Automates installation and configuration of the 24/7 autonomous research agent
# Run: .\setup.ps1

param(
    [string]$MoltbookApiKey = "",
    [string]$ChirperApiKey = "",
    [switch]$SkipInstall = $false,
    [switch]$StartAgent = $false
)

$ErrorActionPreference = "Stop"
$StateDir = "E:\OpenCLAW\state"
$SkillDir = "E:\OpenCLAW-2\skills\autonomous-engine"

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

# Check Node.js installation
function Test-NodeInstallation {
    Write-Header "Checking Prerequisites"
    
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Success "Node.js found: $nodeVersion"
            
            # Check version (need 18+)
            $versionNum = $nodeVersion -replace 'v', '' -split '\.' | Select-Object -First 1
            if ([int]$versionNum -lt 18) {
                Write-Error "Node.js 18+ required. Found: $nodeVersion"
                Write-Info "Download from: https://nodejs.org/"
                exit 1
            }
        } else {
            Write-Error "Node.js not found"
            Write-Info "Please install Node.js 18+ from https://nodejs.org/"
            exit 1
        }
        
        # Check TypeScript
        try {
            $tsVersion = npx tsc --version 2>$null
            Write-Success "TypeScript available"
        } catch {
            Write-Info "TypeScript will be installed with dependencies"
        }
        
    } catch {
        Write-Error "Failed to check Node.js"
        exit 1
    }
}

# Install dependencies
function Install-Dependencies {
    if ($SkipInstall) {
        Write-Info "Skipping dependency installation (--SkipInstall)"
        return
    }
    
    Write-Header "Installing Dependencies"
    
    Push-Location $SkillDir
    
    try {
        # Check if package.json exists
        if (Test-Path "package.json") {
            Write-Info "Found package.json, running npm install..."
            npm install
        } else {
            Write-Info "Creating package.json..."
            
            $packageJson = @"
{
  "name": "openclaw-social-agent",
  "version": "2.0.0",
  "description": "24/7 Autonomous Research Collaboration Agent for OpenCLAW",
  "main": "openclaw-agent.ts",
  "scripts": {
    "start": "ts-node openclaw-agent.ts run",
    "setup": "ts-node openclaw-agent.ts setup",
    "once": "ts-node openclaw-agent.ts once",
    "stats": "ts-node openclaw-agent.ts stats"
  },
  "dependencies": {
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0",
    "@types/node": "^20.0.0"
  },
  "keywords": ["openclaw", "agi", "research", "autonomous", "moltbook", "chirper"],
  "author": "OpenCLAW Team",
  "license": "MIT"
}
"@
            $packageJson | Set-Content "package.json" -Encoding UTF8
            
            Write-Info "Running npm install..."
            npm install
        }
        
        Write-Success "Dependencies installed"
        
    } catch {
        Write-Error "Failed to install dependencies: $_"
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

# Create tsconfig.json if needed
function Initialize-TypeScript {
    Write-Header "Initializing TypeScript"
    
    Push-Location $SkillDir
    
    if (-not (Test-Path "tsconfig.json")) {
        Write-Info "Creating tsconfig.json..."
        
        $tsConfig = @'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": ".",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "types": ["node"]
  },
  "include": ["*.ts"],
  "exclude": ["node_modules", "dist"]
}
'@
        $tsConfig | Set-Content "tsconfig.json" -Encoding UTF8
        Write-Success "tsconfig.json created"
    } else {
        Write-Success "tsconfig.json already exists"
    }
    
    Pop-Location
}

# Setup state directory
function Initialize-StateDirectory {
    Write-Header "Initializing State Directory"
    
    if (-not (Test-Path $StateDir)) {
        New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
        Write-Success "Created state directory: $StateDir"
    } else {
        Write-Success "State directory exists: $StateDir"
    }
    
    # Create .gitignore for state
    $gitignore = @"
# State files - do not commit
*.json
*.log
chirper_queue.json
"@
    $gitignore | Set-Content "$StateDir\.gitignore" -Encoding UTF8
}

# Configure API keys
function Configure-ApiKeys {
    Write-Header "Configuration"
    
    $moltbookKey = $MoltbookApiKey
    $chirperKey = $ChirperApiKey
    
    # Prompt for Moltbook API key if not provided
    if (-not $moltbookKey) {
        Write-Info "Get your Moltbook API key from:"
        Write-Info "https://www.moltbook.com/u/OpenCLAW-Neuromorphic"
        Write-Host ""
        $moltbookKey = Read-Host -Prompt "Enter Moltbook API Key"
        
        if (-not $moltbookKey) {
            Write-Error "Moltbook API Key is required"
            exit 1
        }
    }
    
    # Prompt for Chirper API key (optional)
    if (-not $chirperKey) {
        Write-Host ""
        $chirperResponse = Read-Host -Prompt "Enter Chirper API Key (optional, press Enter to skip)"
        $chirperKey = $chirperResponse
    }
    
    # Save configuration
    Write-Header "Saving Configuration"
    
    Push-Location $SkillDir
    
    try {
        if ($chirperKey) {
            npx ts-node openclaw-agent.ts setup $moltbookKey $chirperKey
        } else {
            npx ts-node openclaw-agent.ts setup $moltbookKey
        }
        Write-Success "Configuration saved"
    } catch {
        Write-Error "Failed to save configuration: $_"
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

# Test the configuration
function Test-Configuration {
    Write-Header "Testing Configuration"
    
    Push-Location $SkillDir
    
    try {
        Write-Info "Running one-time test..."
        npx ts-node openclaw-agent.ts once
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Test completed successfully"
        } else {
            Write-Error "Test failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Error "Test failed: $_"
    }
    
    Pop-Location
}

# Create Windows Service wrapper script
function Create-ServiceWrapper {
    Write-Header "Creating Service Scripts"
    
    # Create start script
    $startScript = @"
# OpenCLAW Social Agent - Start Script
# Run this to start the 24/7 autonomous agent

cd "$SkillDir"
Write-Host "Starting OpenCLAW Social Agent..." -ForegroundColor Green
Write-Host "Logs: $StateDir\openclaw-agent.log" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""
npx ts-node openclaw-agent.ts run
"@
    $startScript | Set-Content "$SkillDir\start.ps1" -Encoding UTF8
    
    # Create background service script (no window)
    $serviceScript = @"
# OpenCLAW Social Agent - Background Service
# Run this to start the agent in background

`$proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SkillDir\start.ps1`"" -PassThru
Write-Host "OpenCLAW Agent started as process ID: `$(`$proc.Id)"
Write-Host "Log file: $StateDir\openclaw-agent.log"
`$proc.Id | Set-Content "$StateDir\agent.pid"
"@
    $serviceScript | Set-Content "$SkillDir\service.ps1" -Encoding UTF8
    
    # Create stop script
    $stopScript = @"
# OpenCLAW Social Agent - Stop Script

if (Test-Path "$StateDir\agent.pid") {
    `$pid = Get-Content "$StateDir\agent.pid"
    try {
        Stop-Process -Id `$pid -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped agent process `$pid" -ForegroundColor Green
        Remove-Item "$StateDir\agent.pid" -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Could not stop process `$(`$pid), may already be stopped" -ForegroundColor Yellow
    }
} else {
    # Try to find by process name
    `$procs = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { `$_.CommandLine -match "openclaw-agent" }
    if (`$procs) {
        `$procs | ForEach-Object { 
            Stop-Process -Id `$_.Id -Force
            Write-Host "Stopped process `$(`$_.Id)" -ForegroundColor Green
        }
    } else {
        Write-Host "No agent process found" -ForegroundColor Yellow
    }
}
"@
    $stopScript | Set-Content "$SkillDir\stop.ps1" -Encoding UTF8
    
    # Create status script
    $statusScript = @"
# OpenCLAW Social Agent - Status Check

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "OpenCLAW Social Agent Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if running
`$running = `$false
if (Test-Path "$StateDir\agent.pid") {
    `$pid = Get-Content "$StateDir\agent.pid"
    try {
        `$proc = Get-Process -Id `$pid -ErrorAction Stop
        `$running = `$true
        Write-Host "Status: RUNNING" -ForegroundColor Green
        Write-Host "Process ID: `$pid" -ForegroundColor Green
        Write-Host "Start Time: `$(`$proc.StartTime)" -ForegroundColor Green
    } catch {
        Write-Host "Status: STOPPED (stale PID file)" -ForegroundColor Red
        Remove-Item "$StateDir\agent.pid" -ErrorAction SilentlyContinue
    }
} else {
    # Check for node processes
    `$procs = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { `$_.CommandLine -match "openclaw-agent" }
    if (`$procs) {
        `$running = `$true
        Write-Host "Status: RUNNING (found node process)" -ForegroundColor Green
        `$procs | ForEach-Object {
            Write-Host "Process `$(`$_.Id): `$(`$_.StartTime)" -ForegroundColor Green
        }
    } else {
        Write-Host "Status: STOPPED" -ForegroundColor Red
    }
}

# Show stats
cd "$SkillDir"
npx ts-node openclaw-agent.ts stats

# Show recent log entries
if (Test-Path "$StateDir\openclaw-agent.log") {
    Write-Host "`n--- Last 10 Log Entries ---" -ForegroundColor Yellow
    Get-Content "$StateDir\openclaw-agent.log" -Tail 10
}

Write-Host "`n========================================" -ForegroundColor Cyan
"@
    $statusScript | Set-Content "$SkillDir\status.ps1" -Encoding UTF8
    
    Write-Success "Service scripts created"
    Write-Info "  - start.ps1    : Start agent in foreground"
    Write-Info "  - service.ps1  : Start agent in background"
    Write-Info "  - stop.ps1     : Stop the agent"
    Write-Info "  - status.ps1   : Check agent status"
}

# Create README for setup
function Create-Readme {
    $readme = @"
# OpenCLAW Social Agent Setup

## Quick Start

### 1. Setup (already done!)
This setup script has configured your agent.

### 2. Start the Agent

**Option A: Foreground (for testing)**
```powershell
.\start.ps1
```

**Option B: Background (for 24/7 operation)**
```powershell
.\service.ps1
```

### 3. Monitor

Check status:
```powershell
.\status.ps1
```

View logs:
```powershell
Get-Content $StateDir\openclaw-agent.log -Wait
```

### 4. Stop
```powershell
.\stop.ps1
```

## Manual Commands

Setup:
```
npx ts-node openclaw-agent.ts setup <MOLTBOOK_API_KEY> [CHIRPER_API_KEY]
```

Run 24/7:
```
npx ts-node openclaw-agent.ts run
```

Run once (test):
```
npx ts-node openclaw-agent.ts once
```

View stats:
```
npx ts-node openclaw-agent.ts stats
```

## Links

- Moltbook Profile: https://www.moltbook.com/u/OpenCLAW-Neuromorphic
- ArXiv Papers: https://arxiv.org/search/cs?searchtype=author&query=de+Lafuente,+F+A
- GitHub: https://github.com/Agnuxo1
"@
    $readme | Set-Content "$SkillDir\SETUP_README.md" -Encoding UTF8
}

# Main execution
function Main {
    Write-Header "OpenCLAW Social Agent Setup"
    Write-Info "This script will install and configure the 24/7 autonomous research agent"
    Write-Info "Target directory: $SkillDir"
    
    # Check if skill directory exists
    if (-not (Test-Path $SkillDir)) {
        Write-Error "Skill directory not found: $SkillDir"
        Write-Info "Please ensure OpenCLAW is installed correctly"
        exit 1
    }
    
    # Run setup steps
    Test-NodeInstallation
    Install-Dependencies
    Initialize-TypeScript
    Initialize-StateDirectory
    Configure-ApiKeys
    Test-Configuration
    Create-ServiceWrapper
    Create-Readme
    
    # Final summary
    Write-Header "Setup Complete!"
    Write-Success "OpenCLAW Social Agent is ready"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Start the agent:  .\start.ps1    (foreground)" -ForegroundColor White
    Write-Host "                      .\service.ps1  (background)" -ForegroundColor White
    Write-Host "  2. Check status:     .\status.ps1" -ForegroundColor White
    Write-Host "  3. View logs:        Get-Content $StateDir\openclaw-agent.log -Wait" -ForegroundColor White
    Write-Host "  4. Stop agent:       .\stop.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "See SETUP_README.md for detailed instructions" -ForegroundColor Yellow
    
    # Start if requested
    if ($StartAgent) {
        Write-Host ""
        Write-Header "Starting Agent"
        & "$SkillDir\start.ps1"
    }
}

# Run main
Main
