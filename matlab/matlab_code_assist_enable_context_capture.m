function path = matlab_code_assist_enable_context_capture()
%MATLAB_CODE_ASSIST_ENABLE_CONTEXT_CAPTURE Start diary-based terminal capture.

path = matlab_code_assist_context_file();

if exist(path, "file") ~= 2
    fclose(fopen(path, "a"));
end

diary off;
diary(path);
diary on;

fprintf("MATLAB Code Assist is capturing Command Window transcript to:\n%s\n", path);
end
