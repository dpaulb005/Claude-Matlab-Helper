function code = ai(requestText, target)
%AI MATLAB Command Window helper for Codex-assisted code generation.
%
% Examples:
%   ai("write a function that plots a sine wave from 0 to 10 seconds")
%   ai("write a helper to parse CSV lines", "editor")
%   ai("show code for a bar chart example", "command")

if nargin < 1
    error("ai:MissingPrompt", "Provide a prompt string, for example ai(""plot a sine wave"").");
end

if nargin < 2 || strlength(string(target)) == 0
    target = "command";
else
    target = string(target);
end

code = matlab_code_assist_command(string(requestText), target);
end
