function historyText = matlab_code_assist_history(limit)
%MATLAB_CODE_ASSIST_HISTORY Return recent MATLAB command history text.

if nargin == 0 || isempty(limit)
    limit = 40;
end

commands = matlab_code_assist_history_cell();
if isempty(commands)
    historyText = "";
    return;
end

startIndex = max(1, numel(commands) - limit + 1);
recent = commands(startIndex:end);
historyText = strjoin(string(recent), newline);
end

function commands = matlab_code_assist_history_cell()
commands = {};

try
    import com.mathworks.mlservices.MLCommandHistoryServices
    rawHistory = MLCommandHistoryServices.getSessionHistory;
catch
    return;
end

try
    commands = cell(rawHistory);
    commands = commands(:)';
    return;
catch
end

try
    n = rawHistory.size();
    commands = cell(1, n);
    for idx = 1:n
        commands{idx} = char(rawHistory.get(idx - 1));
    end
catch
    commands = {};
end
end
