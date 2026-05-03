function tests = test_parse_mode
%TEST_PARSE_MODE Function tests for matlab_code_assist_parse_mode.
tests = functiontests(localfunctions);
end

function setup(~)
projectDir = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectDir, "matlab"));
end

function testParseModeCommandWithVerification(testCase)
[result, handled] = matlab_code_assist_parse_mode("mode sampling exam verify");

verifyTrue(testCase, handled);
verifyEqual(testCase, result.action, "set");
verifyEqual(testCase, result.state.topicMode, "sampling");
verifyEqual(testCase, result.state.responseMode, "exam");
verifyTrue(testCase, result.state.wantsVerification);
verifyFalse(testCase, result.state.wantsVisualization);
verifyEqual(testCase, result.state.modeSource, "explicit");
end

function testResponseOnlyModePreservesDefaultModeSource(testCase)
[result, handled] = matlab_code_assist_parse_mode("mode exam verify");

verifyTrue(testCase, handled);
verifyEqual(testCase, result.state.topicMode, "general");
verifyEqual(testCase, result.state.responseMode, "exam");
verifyEqual(testCase, result.state.modeSource, "default");
verifyTrue(testCase, result.state.wantsVerification);
end

function testParseClearModeCommand(testCase)
[result, handled] = matlab_code_assist_parse_mode("clear mode");

verifyTrue(testCase, handled);
verifyEqual(testCase, result.action, "clear");
end

function testNonModePromptFallsThrough(testCase)
[result, handled] = matlab_code_assist_parse_mode("Explain convolution intuitively");

verifyFalse(testCase, handled);
verifyEmpty(testCase, fieldnames(result));
end
