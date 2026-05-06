function options = matlab_code_assist_request_options(requestText, target)
%MATLAB_CODE_ASSIST_REQUEST_OPTIONS Build request options for the local Python helper.

if nargin < 1 %#ok<INUSD>
    requestText = "";
end

if nargin < 2 %#ok<INUSD>
    target = "command";
end

state = matlab_code_assist_mode_state("get");
options = struct( ...
    "topicMode", char(state.topicMode), ...
    "responseMode", char(state.responseMode), ...
    "wantsVerification", logical(state.wantsVerification), ...
    "wantsVisualization", logical(state.wantsVisualization), ...
    "incognito", logical(state.incognito), ...
    "modeSource", char(state.modeSource));
end
