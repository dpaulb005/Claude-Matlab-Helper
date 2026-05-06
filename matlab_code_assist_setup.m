function matlab_code_assist_setup(varargin) %#ok<INUSD>
%MATLAB_CODE_ASSIST_SETUP Bootstrap the organized MATLAB Code Assist project.

projectDir = fileparts(mfilename("fullpath"));
matlabDir = fullfile(projectDir, "matlab");
addpath(matlabDir);
matlab_code_assist_setup_main();
end
