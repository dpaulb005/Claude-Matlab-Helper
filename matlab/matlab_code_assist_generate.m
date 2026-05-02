function response = matlab_code_assist_generate(snapshot, requestText)
%MATLAB_CODE_ASSIST_GENERATE Call the local Codex bridge from MATLAB.

if nargin < 2
    error("matlab_code_assist_generate:MissingInput", ...
        "Snapshot and request text are required.");
end

requestBody = struct( ...
    "model", "claude-opus-4-7", ...
    "payload", struct( ...
        "request", char(requestText), ...
        "target", char(snapshot.target), ...
        "problemLabel", char(snapshot.problemLabel), ...
        "problemContext", char(matlab_code_assist_problem_context(requestText, snapshot.problemLabel)), ...
        "editor", snapshot.editor, ...
        "commandWindow", snapshot.commandWindow));

import matlab.net.URI
import matlab.net.http.RequestMessage
import matlab.net.http.RequestMethod
import matlab.net.http.MessageBody
import matlab.net.http.HeaderField

uri = URI("http://127.0.0.1:8765/generate");
headers = HeaderField("Content-Type", "application/json");
body = MessageBody(requestBody);
request = RequestMessage(RequestMethod.POST, headers, body);
httpOptions = matlab.net.http.HTTPOptions("ConnectTimeout", 10);
responseMessage = request.send(uri, httpOptions);

if responseMessage.StatusCode ~= matlab.net.http.StatusCode.OK
    error("matlab_code_assist_generate:BridgeError", ...
        "Bridge request failed with status %s.", string(responseMessage.StatusCode));
end

response = responseMessage.Body.Data;
if ~isstruct(response) || ~isfield(response, "code")
    error("matlab_code_assist_generate:InvalidResponse", ...
        "Bridge returned an invalid response.");
end
end
