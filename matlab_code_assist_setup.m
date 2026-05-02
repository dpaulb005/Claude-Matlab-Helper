function matlab_code_assist_setup(startBridge)
%MATLAB_CODE_ASSIST_SETUP Bootstrap the organized MATLAB Code Assist project.

if nargin < 1
    startBridge = true;
end

projectDir = fileparts(mfilename("fullpath"));
matlabDir = fullfile(projectDir, "matlab");
addpath(matlabDir);
matlab_code_assist_setup_main(startBridge);
end
