function status = matlab_code_assist_terminal_mode(action, target)
%MATLAB_CODE_ASSIST_TERMINAL_MODE Watch Command History for ~queries.
%
% Example:
%   matlab_code_assist_terminal_mode("on")
%   ~write a function that computes RMS
%
% MATLAB still evaluates "~..." as normal syntax first, so an invalid
% expression message may appear before the assistant responds.

if nargin == 0 || strlength(string(action)) == 0
    action = "status";
else
    action = lower(string(action));
end

if nargin < 2 || strlength(string(target)) == 0
    target = "command";
else
    target = lower(string(target));
end

timerTag = "matlabCodeAssistTerminalTimer";
stateKey = "matlabCodeAssistTerminalState";

switch action
    case {"on", "start", "enable"}
        existingTimer = timerfindall("Tag", timerTag);
        if ~isempty(existingTimer)
            stop(existingTimer);
            delete(existingTimer);
        end

        state = struct( ...
            "lastCount", numel(localHistoryCell()), ...
            "target", target, ...
            "busy", false, ...
            "lastProcessed", "");
        setappdata(0, stateKey, state);

        t = timer( ...
            "ExecutionMode", "fixedSpacing", ...
            "BusyMode", "drop", ...
            "Period", 1.0, ...
            "StartDelay", 0.5, ...
            "Tag", timerTag, ...
            "TimerFcn", @(~, ~) localPoll(stateKey));
        start(t);

        fprintf("MATLAB Code Assist terminal mode enabled. Type ~your prompt in the Command Window.\n");

    case {"off", "stop", "disable"}
        existingTimer = timerfindall("Tag", timerTag);
        if ~isempty(existingTimer)
            stop(existingTimer);
            delete(existingTimer);
        end
        if isappdata(0, stateKey)
            rmappdata(0, stateKey);
        end
        fprintf("MATLAB Code Assist terminal mode disabled.\n");

    case "status"
    otherwise
        error("matlab_code_assist_terminal_mode:InvalidAction", ...
            "Action must be 'on', 'off', or 'status'.");
end

timers = timerfindall("Tag", timerTag);
status = struct( ...
    "enabled", ~isempty(timers), ...
    "target", target);
end

function localPoll(stateKey)
if ~isappdata(0, stateKey)
    return;
end

state = getappdata(0, stateKey);
if state.busy
    return;
end

commands = localHistoryCell();
newCount = numel(commands);
if newCount <= state.lastCount
    return;
end

newCommands = commands(state.lastCount + 1:newCount);
state.lastCount = newCount;
setappdata(0, stateKey, state);

for idx = 1:numel(newCommands)
    commandText = strtrim(string(newCommands{idx}));
    if strlength(commandText) < 2 || ~startsWith(commandText, "~")
        continue;
    end

    requestText = strtrim(extractAfter(commandText, 1));
    if strlength(requestText) == 0
        continue;
    end

    if commandText == state.lastProcessed
        continue;
    end

    state.busy = true;
    state.lastProcessed = commandText;
    setappdata(0, stateKey, state);

    try
        fprintf("\n%% MATLAB Code Assist processing: %s\n", requestText);
        matlab_code_assist_command(requestText, state.target);
    catch err
        fprintf(2, "\nMATLAB Code Assist error: %s\n", err.message);
    end

    state = getappdata(0, stateKey);
    state.busy = false;
    setappdata(0, stateKey, state);
    break;
end
end

function commands = localHistoryCell()
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
