function matlab_code_assist_apply_to_editor(code)
%MATLAB_CODE_ASSIST_APPLY_TO_EDITOR Replace active editor content when available.

code = char(code);

if exist("matlab.desktop.editor.getActive", "file") == 5 || ...
        exist("matlab.desktop.editor.getActive", "builtin") == 5 || ...
        exist("matlab.desktop.editor.getActive", "builtin") == 6
    editorDoc = matlab.desktop.editor.getActive;
    if ~isempty(editorDoc)
        editorDoc.Text = code;
        return;
    end
end

assignin("base", "matlabCodeAssistLast", string(code));
error("matlab_code_assist:NoEditor", ...
    "No active MATLAB editor document was found. Generated code was saved to variable matlabCodeAssistLast.");
end
