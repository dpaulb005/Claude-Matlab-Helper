function [result, handled] = matlab_code_assist_parse_mode(requestText)
%MATLAB_CODE_ASSIST_PARSE_MODE Parse mode-control commands for lrn(...).

text = lower(strtrim(string(requestText)));
result = struct();
handled = false;

if strlength(text) == 0
    return;
end

if text == "clear mode"
    result.action = "clear";
    handled = true;
    return;
end

if text == "show mode"
    result.action = "show";
    handled = true;
    return;
end

if startsWith(text, "mode ")
    tokens = split(extractAfter(text, strlength("mode ")), whitespacePattern);
    tokens = tokens(strlength(tokens) > 0);

    if isempty(tokens)
        error("matlab_code_assist_parse_mode:MissingMode", ...
            "Provide at least one topic or response mode after 'mode'.");
    end

    state = matlab_code_assist_mode_state("get");
    topicModes = ["general", "convolution", "laplace", "fourier", "sampling", "stability", "response"];
    responseModes = ["concise", "derivation", "exam"];
    sawTopicToken = false;

    for index = 1:numel(tokens)
        token = tokens(index);
        if any(token == topicModes)
            state.topicMode = token;
            sawTopicToken = true;
        elseif any(token == responseModes)
            state.responseMode = token;
        elseif token == "verify" || token == "verification"
            state.wantsVerification = true;
        elseif token == "visual" || token == "visualize" || token == "visualization"
            state.wantsVisualization = true;
        elseif token == "incognito"
            state.incognito = true;
        elseif token == "noincognito"
            state.incognito = false;
        elseif token == "noverify"
            state.wantsVerification = false;
        elseif token == "novisual"
            state.wantsVisualization = false;
        else
            error("matlab_code_assist_parse_mode:InvalidToken", ...
                "Unknown mode token: %s", token);
        end
    end

    if sawTopicToken
        state.modeSource = "explicit";
    end

    result.action = "set";
    result.state = state;
    handled = true;
end
end
