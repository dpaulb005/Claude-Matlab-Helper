function contextText = matlab_code_assist_terminal_context(commandLimit, charLimit)
%MATLAB_CODE_ASSIST_TERMINAL_CONTEXT Return recent terminal input/output context.

if nargin < 1 || isempty(commandLimit)
    commandLimit = 120;
end

if nargin < 2 || isempty(charLimit)
    charLimit = 12000;
end

historyText = matlab_code_assist_history(commandLimit);
diaryText = localReadDiary(charLimit);

parts = strings(0, 1);
if strlength(historyText) > 0
    parts(end + 1) = "Recent command history:" + newline + historyText; %#ok<AGROW>
end
if strlength(diaryText) > 0
    parts(end + 1) = "Recent command window transcript:" + newline + diaryText; %#ok<AGROW>
end

if isempty(parts)
    contextText = "";
else
    contextText = strjoin(parts, newline + newline + "---" + newline + newline);
end
end

function diaryText = localReadDiary(charLimit)
diaryText = "";
path = matlab_code_assist_context_file();
if exist(path, "file") ~= 2
    return;
end

raw = string(fileread(path));
if strlength(raw) == 0
    return;
end

if strlength(raw) > charLimit
    raw = extractAfter(raw, strlength(raw) - charLimit);
end

diaryText = strtrim(raw);
end
