function varargout = help(varargin)
%HELP MATLAB help wrapper with assistant prompt support.
%
% Assistant examples:
%   help("write a function that plots a sine wave from 0 to 10 seconds")
%   help("write a helper to parse CSV lines", "editor")
%   help("show code for a histogram example", "command")
%
% Standard help examples still pass through:
%   help plot
%   help("plot")

if shouldRouteToAssistant(varargin{:})
    target = "command";
    if nargin >= 2
        target = string(varargin{2});
    end
    code = matlab_code_assist_command(string(varargin{1}), target);
    if nargout > 0
        varargout{1} = code;
    end
    return;
end

[varargout{1:nargout}] = builtin("help", varargin{:});
end

function tf = shouldRouteToAssistant(varargin)
tf = false;

if nargin == 0
    return;
end

firstArg = varargin{1};
if ~(ischar(firstArg) || (isstring(firstArg) && isscalar(firstArg)))
    return;
end

prompt = strtrim(string(firstArg));
if strlength(prompt) == 0
    return;
end

if nargin >= 2
    secondArg = lower(string(varargin{2}));
    if any(secondArg == ["editor", "command"])
        tf = true;
        return;
    end
end

containsWhitespace = contains(prompt, whitespacePattern);
containsSentencePunctuation = contains(prompt, [",", ".", "?", "!", ":"]);
looksLikeNaturalLanguage = containsWhitespace || containsSentencePunctuation;

if looksLikeNaturalLanguage
    tf = true;
end
end
