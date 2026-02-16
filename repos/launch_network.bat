@echo off
title OpenCLAW Network Launcher
echo 🦅 Launching OpenCLAW Autonomous Network...
echo ===========================================

echo.
echo Starting Literary Agent 2 (GLM5)...
start "OpenCLAW Literary 2 (GLM5)" /d "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary2" cmd /k ".venv\Scripts\python main.py"

echo Starting Literary Agent 1 (Python)...
start "OpenCLAW Literary 1" /d "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-literary" cmd /k ".venv\Scripts\python main.py"

echo Starting Scientific Agent v2 (Python)...
start "OpenCLAW Scientific v2" /d "E:\OpenCLAW-4\repos\OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform" cmd /k ".venv\Scripts\python main.py daemon"

echo Starting Moltbook Agent (TS)...
start "OpenCLAW Moltbook Agent" /d "E:\OpenCLAW-4\repos\OpenCLAW-2-moltbook-Agent" cmd /k "npm start"

echo Starting Literary Agent (TS)...
start "OpenCLAW Literary (TS)" /d "E:\OpenCLAW-4\repos\OpenCLAW-2-Literary-Agent" cmd /k "npm start"

echo.
echo 🚀 All agents launched in separate windows.
echo Monitor them for 'Heartbeat' or 'Cycle complete' messages.
pause
