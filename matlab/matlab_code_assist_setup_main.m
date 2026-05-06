function matlab_code_assist_setup_main(~)
%MATLAB_CODE_ASSIST_SETUP_MAIN Add the MATLAB code folder to the path.

projectDir = matlab_code_assist_project_root();
matlabDir = fullfile(projectDir, "matlab");
addpath(matlabDir);
matlab_code_assist_healthcheck();

fprintf("MATLAB Code Assist is ready from:\n%s\n", projectDir);
fprintf("Try lrn(""what does BIBO stable mean?"") or clr.\n");
end
