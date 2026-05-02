function path = matlab_code_assist_context_file()
%MATLAB_CODE_ASSIST_CONTEXT_FILE Return the session transcript file path.

stateDir = fullfile(matlab_code_assist_runtime_dir(), "state");

if ~exist(stateDir, "dir")
    mkdir(stateDir);
end

path = fullfile(stateDir, "command_window_diary.txt");
end
