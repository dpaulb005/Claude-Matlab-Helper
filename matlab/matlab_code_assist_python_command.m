function command = matlab_code_assist_python_command(scriptPath, varargin)
%MATLAB_CODE_ASSIST_PYTHON_COMMAND Build a shell-safe Python command.

projectDir = matlab_code_assist_project_root();
[pythonExecutable, pythonArgs] = localDetectPythonCommand(projectDir);

parts = strings(0, 1);
parts(end + 1) = localShellQuote(pythonExecutable);

if strlength(pythonArgs) > 0
    argParts = split(pythonArgs);
    argParts = argParts(strlength(argParts) > 0);
    for index = 1:numel(argParts)
        parts(end + 1) = localShellQuote(argParts(index)); %#ok<AGROW>
    end
end

parts(end + 1) = localShellQuote(scriptPath);

for index = 1:numel(varargin)
    parts(end + 1) = localShellQuote(string(varargin{index})); %#ok<AGROW>
end

command = strjoin(parts, " ");
end

function [pythonExecutable, pythonArgs] = localDetectPythonCommand(projectDir)
if ispc
    [pythonExecutable, pythonArgs] = localDetectWindowsPythonCommand(projectDir);
else
    pythonExecutable = localDetectUnixPythonCommand(projectDir);
    pythonArgs = "";
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

error("matlab_code_assist_python_command:PythonNotFound", ...
    "Could not find a usable Python launcher. Install Python 3 or make 'py -3' available.");
end

function pythonExecutable = localDetectUnixPythonCommand(projectDir)
venvPython = fullfile(projectDir, '.venv', 'bin', 'python');
if isfile(venvPython)
    pythonExecutable = string(venvPython);
    return;
end

candidates = {"python3", "python"};

for index = 1:numel(candidates)
    [status, ~] = system(sprintf('command -v %s >/dev/null 2>&1', candidates{index}));
    if status == 0
        pythonExecutable = candidates{index};
        return;
    end
end

error("matlab_code_assist_python_command:PythonNotFound", ...
    "Could not find python3 or python on the system path.");
end

function quoted = localShellQuote(value)
value = string(value);

if ispc
    dq = string(char(34));
    quoted = dq + replace(value, dq, dq + dq) + dq;
else
    quoted = "'" + replace(value, "'", "'\''") + "'";
end
