function matlab_code_assist_start_bridge()
%MATLAB_CODE_ASSIST_START_BRIDGE Start the local Claude bridge from MATLAB.

if localBridgeIsReachable()
    fprintf("MATLAB Code Assist bridge is already running.\n");
    matlab_code_assist_enable_context_capture();
    return;
end

projectDir = matlab_code_assist_project_root();
scriptPath = fullfile(projectDir, "bridge", "start_bridge.py");
runtimeDir = matlab_code_assist_runtime_dir();
logPath = fullfile(runtimeDir, "bridge.log");

if ~isfile(scriptPath)
    error("matlab_code_assist_start_bridge:MissingScript", ...
        "Could not find start_bridge.py at %s.", scriptPath);
end

command = localBuildLaunchCommand(projectDir, scriptPath, logPath);
[status, output] = system(command);

if status ~= 0
    error("matlab_code_assist_start_bridge:LaunchFailed", ...
        "Failed to start the bridge: %s", strtrim(output));
end

pause(1.0);
fprintf("MATLAB Code Assist bridge launch requested. Log: %s\n", logPath);
matlab_code_assist_enable_context_capture();
end

function reachable = localBridgeIsReachable()
reachable = false;

try
    matlab_code_assist_healthcheck();
    reachable = true;
catch
end
end

function command = localBuildLaunchCommand(projectDir, scriptPath, logPath)
if ispc
    [pythonExecutable, pythonArgs] = localDetectWindowsPythonCommand(projectDir);
    if strlength(pythonArgs) > 0
        pythonArgs = " " + pythonArgs;
    end
    command = sprintf('start "" /B cmd /C ""%s"%s "%s" > "%s" 2>&1""', ...
        pythonExecutable, pythonArgs, scriptPath, logPath);
else
    pythonCommand = localDetectUnixPythonCommand(projectDir);
    command = sprintf('nohup %s "%s" > "%s" 2>&1 &', ...
        pythonCommand, scriptPath, logPath);
end
end

function [pythonExecutable, pythonArgs] = localDetectWindowsPythonCommand(projectDir)
venvPython = fullfile(projectDir, '.venv', 'Scripts', 'python.exe');
if isfile(venvPython)
    pythonExecutable = string(venvPython);
    pythonArgs = "";
    return;
end

candidates = {
    struct("command", "py -3 --version", "executable", "py", "args", "-3")
    struct("command", "python --version", "executable", "python", "args", "")
};

for index = 1:numel(candidates)
    [status, ~] = system(candidates{index}.command);
    if status == 0
        pythonExecutable = candidates{index}.executable;
        pythonArgs = candidates{index}.args;
        return;
    end
end

error("matlab_code_assist_start_bridge:PythonNotFound", ...
    "Could not find a usable Python launcher. Install Python 3 or make 'py -3' available.");
end

function pythonCommand = localDetectUnixPythonCommand(projectDir)
venvPython = fullfile(projectDir, '.venv', 'bin', 'python');
if isfile(venvPython)
    pythonCommand = sprintf('"%s"', venvPython);
    return;
end

candidates = {"python3", "python"};

for index = 1:numel(candidates)
    [status, ~] = system(sprintf('command -v %s >/dev/null 2>&1', candidates{index}));
    if status == 0
        pythonCommand = candidates{index};
        return;
    end
end

error("matlab_code_assist_start_bridge:PythonNotFound", ...
    "Could not find python3 or python on the system path.");
end
