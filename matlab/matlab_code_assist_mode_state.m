function state = matlab_code_assist_mode_state(action, value)
%MATLAB_CODE_ASSIST_MODE_STATE Get or set the active Signals & Systems mode.

key = "matlabCodeAssistModeState";
action = lower(string(action));

switch action
    case "get"
        if isappdata(0, key)
            state = localNormalizeState(getappdata(0, key));
        else
            state = localDefaultState();
        end

    case "set"
        if nargin < 2
            error("matlab_code_assist_mode_state:MissingState", ...
                "A mode state struct is required when setting the active mode.");
        end

        state = localNormalizeState(value);
        setappdata(0, key, state);

    case "clear"
        if isappdata(0, key)
            rmappdata(0, key);
        end
        state = localDefaultState();

    otherwise
        error("matlab_code_assist_mode_state:InvalidAction", ...
            "Action must be ""get"", ""set"", or ""clear"".");
end
end

function state = localDefaultState()
state = struct( ...
    "topicMode", "general", ...
    "responseMode", "concise", ...
    "wantsVerification", false, ...
    "wantsVisualization", false, ...
    "incognito", false, ...
    "modeSource", "default");
end

function state = localNormalizeState(value)
defaultState = localDefaultState();
state = defaultState;

if isstruct(value)
    fieldNames = fieldnames(defaultState);
    for index = 1:numel(fieldNames)
        fieldName = fieldNames{index};
        if isfield(value, fieldName)
            state.(fieldName) = value.(fieldName);
        end
    end
else
    error("matlab_code_assist_mode_state:InvalidState", ...
        "Mode state must be provided as a struct.");
end

state.topicMode = localValidateTopicMode(state.topicMode);
state.responseMode = localValidateResponseMode(state.responseMode);
state.wantsVerification = logical(state.wantsVerification);
state.wantsVisualization = logical(state.wantsVisualization);
state.incognito = logical(state.incognito);
state.modeSource = localValidateModeSource(state.modeSource);
end

function topicMode = localValidateTopicMode(value)
topicMode = lower(strtrim(string(value)));
validModes = ["general", "convolution", "laplace", "fourier", "sampling", "stability", "response"];
if ~any(topicMode == validModes)
    error("matlab_code_assist_mode_state:InvalidTopicMode", ...
        "Unsupported topic mode: %s", topicMode);
end
end

function responseMode = localValidateResponseMode(value)
responseMode = lower(strtrim(string(value)));
validModes = ["concise", "derivation", "exam"];
if ~any(responseMode == validModes)
    error("matlab_code_assist_mode_state:InvalidResponseMode", ...
        "Unsupported response mode: %s", responseMode);
end
end

function modeSource = localValidateModeSource(value)
modeSource = lower(strtrim(string(value)));
validSources = ["default", "explicit"];
if ~any(modeSource == validSources)
    error("matlab_code_assist_mode_state:InvalidModeSource", ...
        "Unsupported mode source: %s", modeSource);
end
end
