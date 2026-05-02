function matlab_code_assist(target)
%MATLAB_CODE_ASSIST Prompt Codex-assisted MATLAB generation from desktop MATLAB.

if nargin == 0 || strlength(string(target)) == 0
    target = "editor";
else
    target = lower(string(target));
end

validTargets = ["editor", "command"];
if ~any(target == validTargets)
    error("matlab_code_assist:InvalidTarget", ...
        "Target must be 'editor' or 'command'.");
end

promptAnswer = inputdlg( ...
    {"Instruction for MATLAB code assist:"}, ...
    "MATLAB Code Assist", ...
    [6 80], ...
    {""});

if isempty(promptAnswer)
    return;
end

requestText = string(promptAnswer{1});
if strlength(strtrim(requestText)) == 0
    return;
end

matlab_code_assist_command(requestText, target);
end
