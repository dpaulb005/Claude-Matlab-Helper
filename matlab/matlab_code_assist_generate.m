function response = matlab_code_assist_generate(snapshot, requestText)
%MATLAB_CODE_ASSIST_GENERATE Run a local Python request helper from MATLAB.

if nargin < 2
    error("matlab_code_assist_generate:MissingInput", ...
        "Snapshot and request text are required.");
end

requestBody = struct( ...
    "model", "claude-opus-4-7", ...
    "payload", struct( ...
        "request", char(requestText), ...
        "target", char(snapshot.target), ...
        "problemLabel", char(snapshot.problemLabel), ...
        "problemContext", char(matlab_code_assist_problem_context(requestText, snapshot.problemLabel)), ...
        "requestOptions", snapshot.requestOptions, ...
        "editor", snapshot.editor, ...
        "workspaceSummary", char(snapshot.workspaceSummary), ...
        "commandWindow", snapshot.commandWindow));

runtimeDir = matlab_code_assist_runtime_dir();
requestPath = fullfile(runtimeDir, sprintf("claude-request-%s.json", char(java.util.UUID.randomUUID())));
responsePath = fullfile(runtimeDir, sprintf("claude-response-%s.json", char(java.util.UUID.randomUUID())));
cleanup = onCleanup(@() localCleanupFiles(requestPath, responsePath)); %#ok<NASGU>

fid = fopen(requestPath, "w");
if fid == -1
    error("matlab_code_assist_generate:RequestWriteFailed", ...
        "Could not create request file at %s.", requestPath);
end
fwrite(fid, jsonencode(requestBody), "char");
fclose(fid);

scriptPath = fullfile(matlab_code_assist_project_root(), "bridge", "run_claude_request.py");
command = matlab_code_assist_python_command(scriptPath, ...
    "--input", requestPath, ...
    "--output", responsePath);
[status, output] = system(command);

if ~isfile(responsePath)
    error("matlab_code_assist_generate:NoResponseFile", ...
        "Python helper did not create a response file. Shell output: %s", strtrim(output));
end

response = jsondecode(fileread(responsePath));
if status ~= 0 || ~isfield(response, "ok") || ~response.ok
    helperError = localFieldOr(response, "error", strtrim(output));
    error("matlab_code_assist_generate:PythonHelperError", "%s", helperError);
end

if ~isstruct(response) || ~isfield(response, "code")
    error("matlab_code_assist_generate:InvalidResponse", ...
        "Python helper returned an invalid response.");
end
end

function value = localFieldOr(data, fieldName, fallback)
if isstruct(data) && isfield(data, fieldName)
    value = string(data.(fieldName));
else
    value = string(fallback);
end
end

function localCleanupFiles(varargin)
for index = 1:nargin
    path = varargin{index};
    if isfile(path)
        delete(path);
    end
end
end
