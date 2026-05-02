function path = matlab_code_assist_runtime_dir()
%MATLAB_CODE_ASSIST_RUNTIME_DIR Return the per-user runtime directory.

path = fullfile(tempdir, "matlab-code-assist");

if ~exist(path, "dir")
    mkdir(path);
end
end
