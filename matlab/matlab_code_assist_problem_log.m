function value = matlab_code_assist_problem_log(action, varargin)
%MATLAB_CODE_ASSIST_PROBLEM_LOG Store and retrieve per-problem session history.

key = "matlabCodeAssistProblemLog";
action = lower(string(action));
logMap = localGetLogMap(key);

switch action
    case "append"
        if numel(varargin) < 3
            error("matlab_code_assist_problem_log:MissingInput", ...
                "Append requires problem label, request text, and response text.");
        end

        problemLabel = char(matlab_code_assist_normalize_problem_label(varargin{1}));
        entry = struct( ...
            "timestamp", char(string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"))), ...
            "request", char(string(varargin{2})), ...
            "response", char(string(varargin{3})));

        if isKey(logMap, problemLabel)
            entries = logMap(problemLabel);
        else
            entries = {};
        end

        entries{end + 1} = entry; %#ok<AGROW>
        if numel(entries) > 12
            entries = entries(max(1, end - 11):end);
        end

        logMap(problemLabel) = entries;
        setappdata(0, key, logMap);
        value = entries;

    case "get"
        if isempty(varargin)
            value = logMap;
            return;
        end

        problemLabel = char(matlab_code_assist_normalize_problem_label(varargin{1}));
        if isKey(logMap, problemLabel)
            value = logMap(problemLabel);
        else
            value = {};
        end

    case "clear"
        if isempty(varargin)
            if isappdata(0, key)
                rmappdata(0, key);
            end
            value = containers.Map("KeyType", "char", "ValueType", "any");
            return;
        end

        problemLabel = char(matlab_code_assist_normalize_problem_label(varargin{1}));
        if isKey(logMap, problemLabel)
            remove(logMap, problemLabel);
            setappdata(0, key, logMap);
        end
        value = logMap;

    otherwise
        error("matlab_code_assist_problem_log:InvalidAction", ...
            "Action must be ""append"", ""get"", or ""clear"".");
end
end

function logMap = localGetLogMap(key)
if isappdata(0, key)
    logMap = getappdata(0, key);
else
    logMap = containers.Map("KeyType", "char", "ValueType", "any");
end
end

function label = matlab_code_assist_normalize_problem_label(problemLabel)
label = lower(strtrim(string(problemLabel)));

if ~matches(label, "^\d+[a-z]{0,2}$")
    error("matlab_code_assist_problem_log:InvalidProblemLabel", ...
        "Problem labels must look like 1, 2, 1a, 1b, or 12c.");
end
end
