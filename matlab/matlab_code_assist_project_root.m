function path = matlab_code_assist_project_root()
%MATLAB_CODE_ASSIST_PROJECT_ROOT Return the project root directory.

path = fileparts(fileparts(mfilename("fullpath")));
end
