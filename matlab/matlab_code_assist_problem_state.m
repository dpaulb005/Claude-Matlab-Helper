function value = matlab_code_assist_problem_state(action, problemLabel)
%MATLAB_CODE_ASSIST_PROBLEM_STATE Get or set the active problem context label.

key = "matlabCodeAssistProblemLabel";
action = lower(string(action));

switch action
    case "get"
        if isappdata(0, key)
            value = string(getappdata(0, key));
        else
            value = "";
        end

    case "set"
        if nargin < 2
            error("matlab_code_assist_problem_state:MissingProblemLabel", ...
                "A problem label is required when setting the problem context.");
        end

        value = matlab_code_assist_normalize_problem_label(problemLabel);
        setappdata(0, key, char(value));

    case "clear"
        if isappdata(0, key)
            rmappdata(0, key);
        end
        value = "";

    otherwise
        error("matlab_code_assist_problem_state:InvalidAction", ...
            "Action must be ""get"", ""set"", or ""clear"".");
end
end

function label = matlab_code_assist_normalize_problem_label(problemLabel)
label = lower(strtrim(string(problemLabel)));

if ~matches(label, "^\d+[a-z]{0,2}$")
    error("matlab_code_assist_problem_state:InvalidProblemLabel", ...
        "Problem labels must look like 1, 2, 1a, 1b, or 12c.");
end
end
