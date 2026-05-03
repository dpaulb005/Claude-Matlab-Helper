function tests = test_mode_state
%TEST_MODE_STATE Function tests for matlab_code_assist_mode_state.
tests = functiontests(localfunctions);
end

function setup(testCase)
projectDir = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectDir, "matlab"));
matlab_code_assist_mode_state("clear");
end

function teardown(~)
matlab_code_assist_mode_state("clear");
end

function testDefaultModeIsGeneralConcise(testCase)
state = matlab_code_assist_mode_state("get");
verifyEqual(testCase, state.topicMode, "general");
verifyEqual(testCase, state.responseMode, "concise");
verifyFalse(testCase, state.wantsVerification);
verifyFalse(testCase, state.wantsVisualization);
verifyEqual(testCase, state.modeSource, "default");
end

function testSetModeStatePersistsFlags(testCase)
updated = matlab_code_assist_mode_state("set", struct( ...
    "topicMode", "sampling", ...
    "responseMode", "exam", ...
    "wantsVerification", true, ...
    "wantsVisualization", true, ...
    "modeSource", "explicit"));

verifyEqual(testCase, updated.topicMode, "sampling");
verifyEqual(testCase, updated.responseMode, "exam");
verifyTrue(testCase, updated.wantsVerification);
verifyTrue(testCase, updated.wantsVisualization);
verifyEqual(testCase, updated.modeSource, "explicit");
end
