@echo off
echo 🦅 OpenCLAW Network - Bulk Installer
echo =======================================

echo.
echo [1/8] Installing OpenCLAW-2-Autonomous-Multi-Agent-literary2 (Python)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary2"
if not exist .venv python -m venv .venv
call .venv\Scripts\activate
pip install -r requirements.txt
deactivate

echo.
echo [2/8] Installing OpenCLAW-2-Autonomous-Multi-Agent-literary (Python)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary"
if not exist .venv python -m venv .venv
call .venv\Scripts\activate
pip install -r requirements.txt
deactivate

echo.
echo [3/8] Installing OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform (Python)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform"
if not exist .venv python -m venv .venv
call .venv\Scripts\activate
pip install -r requirements.txt
deactivate

echo.
echo [4/8] Installing OpenCLAW-update-Literary-Agent-24-7-auto (Python)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-update-Literary-Agent-24-7-auto"
if not exist .venv python -m venv .venv
call .venv\Scripts\activate
pip install -r requirements.txt
deactivate

echo.
echo [5/8] Installing OpenCLAW-2-moltbook-Agent (TypeScript)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-2-moltbook-Agent"
call npm install

echo.
echo [6/8] Installing OpenCLAW-2-Literary-Agent (TypeScript)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-2-Literary-Agent"
call npm install

echo.
echo [7/8] Installing OpenCLAW-Autonomous-Multi-Agent-Scientific-Research-Platform (TypeScript)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-Autonomous-Multi-Agent-Scientific-Research-Platform"
call npm install

echo.
echo [8/8] Installing OpenCLAW-2 (Core Platform)...
cd "E:\OpenCLAW-4\repos\OpenCLAW-2"
call npm install

echo.
echo ✅ All agents installed.
pause
