function text = lrn(requestText, target)
%LRN MATLAB Command Window helper for concise answers with MATLAB backup.
%
% Examples:
%   lrn(1)
%   lrn("1a")
%   lrn("mode sampling exam verify")
%   lrn("show mode")
%   lrn("write a function that plots a sine wave from 0 to 10 seconds")
%   lrn("write a function that computes RMS", "editor")
%   lrn("show code for a histogram example", "command")

if nargin < 1
    error("lrn:MissingPrompt", "Provide a prompt string, for example lrn(""plot a sine wave"").");
end

if nargin < 2 || strlength(string(target)) == 0
    target = "command";
else
    target = string(target);
end

[modeCommand, handled] = matlab_code_assist_parse_mode(requestText);
if handled
    text = localHandleModeCommand(modeCommand);
    fprintf("\n%s\n\n", text);
    return;
end

problemLabel = matlab_code_assist_parse_problem_label(requestText);
if strlength(problemLabel) > 0
    matlab_code_assist_problem_state("set", problemLabel);
    text = "Problem context set to Problem " + problemLabel + ".";
    fprintf("\n%s\n\n", text);
    return;
end

text = matlab_code_assist_command(string(requestText), target);
end

function text = localHandleModeCommand(modeCommand)
switch modeCommand.action
    case "set"
        state = matlab_code_assist_mode_state("set", modeCommand.state);
        text = localDescribeModeState("Mode updated", state);
    case "clear"
        state = matlab_code_assist_mode_state("clear");
        text = localDescribeModeState("Mode cleared", state);
    case "show"
        state = matlab_code_assist_mode_state("get");
        text = localDescribeModeState("Current mode", state);
    otherwise
        error("lrn:InvalidModeCommand", "Unsupported mode command action: %s", modeCommand.action);
end
end

function text = localDescribeModeState(prefix, state)
parts = [ ...
    prefix + ": topic=" + state.topicMode, ...
    "response=" + state.responseMode, ...
    "verify=" + string(state.wantsVerification), ...
    "visual=" + string(state.wantsVisualization)];
text = strjoin(parts, ", ");
end

function problemLabel = matlab_code_assist_parse_problem_label(requestText)
problemLabel = "";

if isnumeric(requestText) && isscalar(requestText)
    candidate = string(double(requestText));
elseif (isstring(requestText) || ischar(requestText)) && isscalar(string(requestText))
    candidate = lower(strtrim(string(requestText)));
else
    return;
end

if matches(candidate, "^\d+(\.0+)?$")
    candidate = extractBefore(candidate, ".");
end

if matches(candidate, "^\d+[a-z]{0,2}$")
    problemLabel = candidate;
end
end
