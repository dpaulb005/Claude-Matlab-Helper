function contextText = matlab_code_assist_workspace_context(maxVars, charLimit)
%MATLAB_CODE_ASSIST_WORKSPACE_CONTEXT Summarize useful base-workspace context.

if nargin < 1 || isempty(maxVars)
    maxVars = 20;
end

if nargin < 2 || isempty(charLimit)
    charLimit = 6000;
end

contextText = "";

try
    vars = evalin("base", "whos");
catch
    return;
end

if isempty(vars)
    return;
end

parts = strings(0, 1);
count = min(numel(vars), maxVars);

for index = 1:count
    entry = vars(index);
    sizeText = strjoin(string(entry.size), "x");
    header = sprintf("- %s (%s %s)", entry.name, entry.class, sizeText);
    preview = localPreviewValue(entry.name, 240);
    if strlength(preview) > 0
        parts(end + 1) = string(header) + newline + "  value: " + preview; %#ok<AGROW>
    else
        parts(end + 1) = string(header); %#ok<AGROW>
    end
end

if numel(vars) > maxVars
    parts(end + 1) = sprintf("- ... plus %d more variables", numel(vars) - maxVars); %#ok<AGROW>
end

contextText = strjoin(parts, newline);
if strlength(contextText) > charLimit
    contextText = extractBefore(contextText, charLimit + 1);
end
end

function preview = localPreviewValue(varName, charLimit)
preview = "";

try
    value = evalin("base", varName);
catch
    return;
end

try
    if isa(value, "sym") || isa(value, "symfun")
        preview = string(strtrim(evalin("base", sprintf("evalc('disp(%s)')", varName))));
    elseif isnumeric(value) || islogical(value)
        if isempty(value)
            preview = "[]";
        elseif isscalar(value)
            preview = string(mat2str(value));
        elseif isvector(value) && numel(value) <= 16
            preview = string(mat2str(value));
        elseif numel(value) <= 9
            preview = string(mat2str(value));
        end
    elseif ischar(value)
        if isrow(value)
            preview = string(value);
        else
            rowStrings = strings(size(value, 1), 1);
            for rowIndex = 1:size(value, 1)
                rowStrings(rowIndex) = string(value(rowIndex, :)); %#ok<AGROW>
            end
            preview = strjoin(rowStrings, " | ");
        end
    elseif isstring(value)
        if isscalar(value)
            preview = value;
        elseif numel(value) <= 6
            preview = strjoin(value, ", ");
        end
    elseif iscell(value) && numel(value) <= 6
        preview = string(strtrim(evalin("base", sprintf("evalc('disp(%s)')", varName))));
    elseif isstruct(value) && isscalar(value)
        fields = string(fieldnames(value));
        preview = "fields: " + strjoin(fields, ", ");
    end
catch
    preview = "";
end

preview = strtrim(preview);
if strlength(preview) > charLimit
    preview = extractBefore(preview, charLimit + 1) + " ...";
end
end
