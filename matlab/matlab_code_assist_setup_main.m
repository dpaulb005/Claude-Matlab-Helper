function matlab_code_assist_setup_main(startBridge)
%MATLAB_CODE_ASSIST_SETUP_MAIN Add the MATLAB code folder to the path.

if nargin < 1
    startBridge = true;
end

projectDir = matlab_code_assist_project_root();
matlabDir = fullfile(projectDir, "matlab");
addpath(matlabDir);

if startBridge
    matlab_code_assist_start_bridge();
    pause(1.0);
    matlab_code_assist_healthcheck();
end

fprintf("MATLAB Code Assist is ready from:\n%s\n", projectDir);
fprintf("Try lrn(""what does BIBO stable mean?"") or clr.\n");
end
