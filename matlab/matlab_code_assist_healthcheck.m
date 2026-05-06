function ok = matlab_code_assist_healthcheck()
%MATLAB_CODE_ASSIST_HEALTHCHECK Verify the direct local Claude helper is usable.

runtimeDir = matlab_code_assist_runtime_dir();
responsePath = fullfile(runtimeDir, sprintf("claude-health-%s.json", char(java.util.UUID.randomUUID())));
cleanup = onCleanup(@() localCleanupFile(responsePath)); %#ok<NASGU>

scriptPath = fullfile(matlab_code_assist_project_root(), "bridge", "run_claude_request.py");
command = matlab_code_assist_python_command(scriptPath, ...
    "--healthcheck", ...
    "--output", responsePath);

[status, output] = system(command);

if ~isfile(responsePath)
    error("matlab_code_assist_healthcheck:Unavailable", ...
        "Direct Python helper did not produce a healthcheck response. Shell output: %s", strtrim(output));
end

response = jsondecode(fileread(responsePath));
ok = status == 0 && isfield(response, "ok") && response.ok;

if ok
    disp("MATLAB Code Assist direct mode is ready.");
    return;
end

if isfield(response, "error")
    detail = string(response.error);
else
    detail = string(strtrim(output));
end

error("matlab_code_assist_healthcheck:Unavailable", "%s", detail);
end

function localCleanupFile(path)
if isfile(path)
    delete(path);
end
end
