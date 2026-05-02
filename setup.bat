@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ======================================
echo    MATLAB Code Assist  --  Setup
echo ======================================
echo.

:: ── 1. Python ─────────────────────────────────────────────────
set "PY="
py -3 --version >nul 2>&1
if %errorlevel% equ 0 ( set "PY=py -3" ) else (
    python3 --version >nul 2>&1
    if %errorlevel% equ 0 ( set "PY=python3" ) else (
        python --version >nul 2>&1
        if %errorlevel% equ 0 ( set "PY=python" )
    )
)
if not defined PY (
    echo   [FAIL] Python 3 not found.
    echo          Download from: https://www.python.org/downloads/
    echo          Check "Add Python to PATH" during install.
    pause
    exit /b 1
)
for /f "delims=" %%v in ('!PY! --version 2^>^&1') do echo   [OK]  Python found: %%v

:: ── 2. Dependencies ───────────────────────────────────────────
echo.
echo   --  Installing Python dependencies...
!PY! -m pip install -r requirements.txt -q --disable-pip-version-check
if %errorlevel% neq 0 (
    echo   [FAIL] pip install failed.
    echo          Try manually: !PY! -m pip install -r requirements.txt
    pause
    exit /b 1
)
echo   [OK]  Dependencies installed (anthropic, pymupdf, pypdf^)

:: ── 3. API Key ────────────────────────────────────────────────
echo.
set "KEY_SET=0"
if exist ".env" (
    findstr /c:"ANTHROPIC_API_KEY=sk-" ".env" >nul 2>&1
    if !errorlevel! equ 0 ( set "KEY_SET=1" )
)
if defined ANTHROPIC_API_KEY ( set "KEY_SET=1" )

if "!KEY_SET!"=="1" (
    echo   [OK]  API key already configured
) else (
    echo   Get your key from: https://console.anthropic.com/
    echo.
    :: Use PowerShell to prompt with masked input (shows asterisks)
    for /f "usebackq delims=" %%k in (`powershell -NoProfile -Command ^
        "$k = Read-Host '  Enter ANTHROPIC_API_KEY' -AsSecureString; ^
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($k))"`) do (
        set "ENTERED_KEY=%%k"
    )
    if "!ENTERED_KEY!"=="" (
        echo   [FAIL] No API key entered.
        pause
        exit /b 1
    )
    echo ANTHROPIC_API_KEY=!ENTERED_KEY!> .env
    echo   [OK]  API key saved to .env
)

:: ── 4. Stop any existing bridge on port 8765 ─────────────────
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":8765 "') do (
    taskkill /f /pid %%p >nul 2>&1
)

:: ── 5. Start bridge ───────────────────────────────────────────
echo.
echo   --  Starting bridge...
start /min "MATLAB Code Assist Bridge" cmd /c "!PY! bridge\start_bridge.py > %TEMP%\matlab-code-assist-bridge.log 2>&1"
timeout /t 3 /nobreak >nul

:: ── 6. Health check ───────────────────────────────────────────
echo   --  Testing connection...
curl -s --max-time 4 http://127.0.0.1:8765/health 2>nul | findstr /c:"\"ok\"" >nul
if %errorlevel% equ 0 (
    echo   [OK]  Bridge is running
) else (
    echo   [FAIL] Bridge did not respond.
    echo.
    echo   Log output:
    type "%TEMP%\matlab-code-assist-bridge.log"
    echo.
    pause
    exit /b 1
)

:: ── 7. Done ───────────────────────────────────────────────────
echo.
echo ======================================
echo    Setup complete!
echo ======================================
echo.
echo   Next steps in MATLAB:
echo     1. Run: matlab_code_assist_setup
echo     2. Try: lrn("What is the Laplace transform of a unit step?")
echo.
echo   To restart the bridge later:
echo     bridge\start_bridge.bat
echo.
pause
