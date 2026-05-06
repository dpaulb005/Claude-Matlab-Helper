@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "VENV_DIR=%ROOT%\.venv"
set "VENV_PY=%VENV_DIR%\Scripts\python.exe"
set "HEALTHCHECK_JSON=%TEMP%\claude-matlab-helper-health.json"
set "LAUNCH_MATLAB=1"
if /I "%~1"=="--no-matlab" set "LAUNCH_MATLAB=0"

echo.
echo =============================================
echo   Claude MATLAB Helper - Windows Portable
echo =============================================
echo.
echo Project folder: %ROOT%
echo.

call :detect_python
if errorlevel 1 goto :fail

call :ensure_venv
if errorlevel 1 goto :fail

call :install_requirements
if errorlevel 1 goto :fail

call :ensure_env_key
if errorlevel 1 goto :fail

call :healthcheck
if errorlevel 1 goto :fail

if "%LAUNCH_MATLAB%"=="1" (
    call :launch_matlab
) else (
    echo Skipping MATLAB auto-launch because --no-matlab was provided.
)

echo.
echo =============================================
echo   Portable launcher finished successfully
echo =============================================
echo.
echo If MATLAB did not open automatically:
echo   1. Open MATLAB manually
echo   2. Set Current Folder to:
echo      %ROOT%
echo   3. Run:
echo      matlab_code_assist_setup
echo   4. Try:
echo      lrn("What is the Laplace transform of a unit step?")
echo.
pause
exit /b 0

:detect_python
set "BOOTSTRAP_PY="
for %%C in ("py -3" python python3) do (
    if not defined BOOTSTRAP_PY (
        call %%~C --version >nul 2>&1
        if !errorlevel! equ 0 set "BOOTSTRAP_PY=%%~C"
    )
)
if not defined BOOTSTRAP_PY (
    echo [FAIL] Python 3 was not found.
    echo Install Python from https://www.python.org/downloads/ and enable "Add Python to PATH".
    exit /b 1
)
for /f "delims=" %%V in ('%BOOTSTRAP_PY% --version 2^>^&1') do echo [OK] %%V
exit /b 0

:ensure_venv
if exist "%VENV_PY%" (
    echo [OK] Reusing local virtual environment: %VENV_DIR%
    exit /b 0
)

echo [INFO] Creating local virtual environment...
%BOOTSTRAP_PY% -m venv "%VENV_DIR%"
if errorlevel 1 (
    echo [FAIL] Could not create .venv
    exit /b 1
)
if not exist "%VENV_PY%" (
    echo [FAIL] Virtual environment was created but python.exe was not found.
    exit /b 1
)
echo [OK] Created local virtual environment: %VENV_DIR%
exit /b 0

:install_requirements
echo [INFO] Installing Python requirements into .venv...
"%VENV_PY%" -m pip install --upgrade pip --disable-pip-version-check >nul 2>&1
"%VENV_PY%" -m pip install -r "%ROOT%\requirements.txt" --disable-pip-version-check
if errorlevel 1 (
    echo [FAIL] pip install -r requirements.txt failed.
    exit /b 1
)
echo [OK] Python dependencies installed.
exit /b 0

:ensure_env_key
if defined ANTHROPIC_API_KEY (
    echo [OK] Using ANTHROPIC_API_KEY from the current environment.
    exit /b 0
)

if exist "%ROOT%\.env" (
    findstr /b /c:"ANTHROPIC_API_KEY=" "%ROOT%\.env" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Found ANTHROPIC_API_KEY in .env
        exit /b 0
    )
)

echo [INFO] No API key found yet.
echo Get your Claude API key from: https://console.anthropic.com/
set /p "ENTERED_KEY=Enter ANTHROPIC_API_KEY: "
if not defined ENTERED_KEY (
    echo [FAIL] No API key entered.
    exit /b 1
)
> "%ROOT%\.env" echo ANTHROPIC_API_KEY=!ENTERED_KEY!
set "ANTHROPIC_API_KEY=!ENTERED_KEY!"
echo [OK] Saved ANTHROPIC_API_KEY to .env
exit /b 0

:healthcheck
echo [INFO] Running direct-mode healthcheck...
"%VENV_PY%" "%ROOT%\bridge\run_claude_request.py" --healthcheck --output "%HEALTHCHECK_JSON%" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Direct-mode healthcheck failed.
    if exist "%HEALTHCHECK_JSON%" type "%HEALTHCHECK_JSON%"
    exit /b 1
)
echo [OK] Direct local Claude helper is ready.
exit /b 0

:launch_matlab
set "MATLAB_EXE="
for /f "delims=" %%M in ('where matlab 2^>nul') do (
    if not defined MATLAB_EXE set "MATLAB_EXE=%%M"
)
if not defined MATLAB_EXE (
    for /d %%D in ("C:\Program Files\MATLAB\R20*") do (
        if exist "%%~fD\bin\matlab.exe" if not defined MATLAB_EXE set "MATLAB_EXE=%%~fD\bin\matlab.exe"
    )
)
if not defined MATLAB_EXE (
    echo [WARN] MATLAB executable was not found automatically.
    exit /b 0
)

echo [INFO] Launching MATLAB...
start "MATLAB" "%MATLAB_EXE%" -sd "%ROOT%" -r "try, matlab_code_assist_setup; catch ME, disp(getReport(ME,'extended')); end"
echo [OK] MATLAB launch requested.
exit /b 0

:fail
echo.
echo Portable startup failed.
if exist "%HEALTHCHECK_JSON%" type "%HEALTHCHECK_JSON%"
echo.
pause
exit /b 1
