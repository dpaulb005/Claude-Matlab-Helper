function contextText = matlab_code_assist_problem_context(requestText, activeProblemLabel)
%MATLAB_CODE_ASSIST_PROBLEM_CONTEXT Build scoped problem history context.

activeProblemLabel = string(activeProblemLabel);
referencedLabels = localExtractReferencedLabels(requestText);

labels = strings(0, 1);
if strlength(activeProblemLabel) > 0
    labels(end + 1) = activeProblemLabel; %#ok<AGROW>
end

for index = 1:numel(referencedLabels)
    if ~any(labels == referencedLabels(index))
        labels(end + 1) = referencedLabels(index); %#ok<AGROW>
    end
end

sections = strings(0, 1);
for index = 1:numel(labels)
    entries = matlab_code_assist_problem_log("get", labels(index));
    if isempty(entries)
        continue;
    end

    lines = strings(0, 1);
    for entryIndex = max(1, numel(entries) - 3):numel(entries)
        entry = entries{entryIndex};
        lines(end + 1) = "User: " + string(entry.request); %#ok<AGROW>
        lines(end + 1) = "Assistant: " + string(entry.response); %#ok<AGROW>
    end

    sections(end + 1) = "Problem " + labels(index) + " session history:" + newline + ...
        strjoin(lines, newline); %#ok<AGROW>
end

if isempty(sections)
    contextText = "";
else
    contextText = strjoin(sections, newline + newline + "---" + newline + newline);
end
end

function labels = localExtractReferencedLabels(requestText)
text = lower(char(string(requestText)));
labels = strings(0, 1);

explicitTokens = regexp(text, 'problem\s*(\d+[a-z]{0,2})\b', 'tokens');
inlineTokens = regexp(text, '\b(\d+[a-z]{1,2})\b', 'tokens');
tokens = [explicitTokens, inlineTokens];

for index = 1:numel(tokens)
    label = string(tokens{index}{1});
    if ~any(labels == label)
        labels(end + 1) = label; %#ok<AGROW>
    end
end
end
