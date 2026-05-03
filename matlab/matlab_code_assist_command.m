function code = matlab_code_assist_command(requestText, target)
%MATLAB_CODE_ASSIST_COMMAND Generate MATLAB code for a request.

if nargin < 1 || strlength(strtrim(string(requestText))) == 0
    error("matlab_code_assist_command:EmptyRequest", ...
        "Request text must not be empty.");
end

if nargin < 2 || strlength(string(target)) == 0
    target = "editor";
else
    target = lower(string(target));
end

snapshot = matlab_code_assist_snapshot();
snapshot.target = target;
snapshot.requestOptions = matlab_code_assist_request_options(requestText, target);
response = matlab_code_assist_generate(snapshot, string(requestText));
code = string(response.code);

if strlength(snapshot.problemLabel) > 0
    matlab_code_assist_problem_log("append", snapshot.problemLabel, requestText, code);
end

switch target
    case "command"
        assignin("base", "matlabCodeAssistLast", code);
        fprintf("\n%s\n\n", code);
    case "editor"
        matlab_code_assist_apply_to_editor(code);
    otherwise
        error("matlab_code_assist_command:InvalidTarget", ...
            "Target must be 'editor' or 'command'.");
end
end
