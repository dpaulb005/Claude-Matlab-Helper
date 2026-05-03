function snapshot = matlab_code_assist_snapshot()
%MATLAB_CODE_ASSIST_SNAPSHOT Capture active MATLAB desktop context.

editor = struct( ...
    "fileName", "untitled.m", ...
    "code", "", ...
    "selectedCode", "");

try
    editorDoc = matlab.desktop.editor.getActive;
    if ~isempty(editorDoc)
        editor.code = editorDoc.Text;
        if isprop(editorDoc, "Filename") && strlength(string(editorDoc.Filename)) > 0
            [~, name, ext] = fileparts(editorDoc.Filename);
            editor.fileName = name + ext;
        end

        selection = matlab_code_assist_get_selection(editorDoc);
        if strlength(selection) > 0
            editor.selectedCode = selection;
        end
    end
catch
end

snapshot = struct( ...
    "editor", editor, ...
    "commandWindow", matlab_code_assist_terminal_context(120, 12000), ...
    "problemLabel", matlab_code_assist_problem_state("get"), ...
    "requestOptions", matlab_code_assist_request_options());
end

function selection = matlab_code_assist_get_selection(editorDoc)
selection = "";

try
    if isprop(editorDoc, "SelectedText")
        selection = string(editorDoc.SelectedText);
    end
catch
end
end
