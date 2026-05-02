function ok = matlab_code_assist_healthcheck()
%MATLAB_CODE_ASSIST_HEALTHCHECK Verify the local Codex bridge is reachable.

import matlab.net.URI
import matlab.net.http.RequestMessage
import matlab.net.http.RequestMethod

try
    uri = URI("http://127.0.0.1:8765/health");
    response = RequestMessage(RequestMethod.GET).send(uri);
catch err
    error("matlab_code_assist_healthcheck:Unavailable", ...
        "The local bridge is not running on http://127.0.0.1:8765. Start it with matlab_code_assist_start_bridge, bridge/start_bridge.py, bridge/start_bridge.sh, or bridge/start_bridge.bat. Original error: %s", ...
        err.message);
end

ok = response.StatusCode == matlab.net.http.StatusCode.OK;

if ok
    disp("MATLAB Code Assist bridge is reachable.");
else
    error("matlab_code_assist_healthcheck:Unavailable", ...
        "Bridge returned status %s.", string(response.StatusCode));
end
end
