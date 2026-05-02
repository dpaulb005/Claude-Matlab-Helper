@echo off
setlocal
cd /d "%~dp0"

:: Load ANTHROPIC_API_KEY from .env in project root if not already in environment
if not defined ANTHROPIC_API_KEY (
    if exist "%~dp0..\.env" (
        for /f "usebackq tokens=1,* delims==" %%A in ("%~dp0..\.env") do (
            if "%%A"=="ANTHROPIC_API_KEY" set "ANTHROPIC_API_KEY=%%B"
        )
    )
)

if not defined ANTHROPIC_API_KEY (
    echo ERROR: ANTHROPIC_API_KEY is not set.
    echo Create a .env file in the project root with:
    echo ANTHROPIC_API_KEY=your_key_here
    exit /b 1
)

if defined PYTHON (
    "%PYTHON%" "%~dp0start_bridge.py"
    exit /b %errorlevel%
)

py -3 "%~dp0start_bridge.py"
if %errorlevel% equ 0 exit /b 0

python "%~dp0start_bridge.py"
exit /b %errorlevel%
