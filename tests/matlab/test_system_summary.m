function tests = test_system_summary
%TEST_SYSTEM_SUMMARY Function tests for matlab_code_assist_system_summary.
tests = functiontests(localfunctions);
end

function setup(~)
projectDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectDir, 'matlab'));
end

function testStableSystemFromCoefficients(testCase)
% H(s) = 1/(s^2 + 3s + 2) — poles at s=-1,-2, both stable
result = matlab_code_assist_system_summary('num',[1],'den',[1 3 2],'Plot',false);
verifyTrue(testCase, result.stable);
verifyEqual(testCase, numel(result.poles), 2);
end

function testUnstableSystemFromCoefficients(testCase)
% H(s) = 1/(s^2 - 1) — poles at s=+1,-1 (unstable)
result = matlab_code_assist_system_summary('num',[1],'den',[1 0 -1],'Plot',false);
verifyFalse(testCase, result.stable);
end

function testDiscreteStableSystem(testCase)
% H(z) = 1/(z - 0.5) — pole inside unit circle, stable
result = matlab_code_assist_system_summary('num',[1],'den',[1 -0.5],'Domain','discrete','Plot',false);
verifyTrue(testCase, result.stable);
end

function testDiscreteUnstableSystem(testCase)
% H(z) = 1/(z - 2) — pole outside unit circle, unstable
result = matlab_code_assist_system_summary('num',[1],'den',[1 -2],'Domain','discrete','Plot',false);
verifyFalse(testCase, result.stable);
end

function testResultStructHasRequiredFields(testCase)
result = matlab_code_assist_system_summary('num',[1],'den',[1 3 2],'Plot',false);
required = {'poles','zeros','stable','stability_reason','domain','H_sym','h_time'};
for k = 1:numel(required)
    verifyTrue(testCase, isfield(result, required{k}), ['Missing: ' required{k}]);
end
end

function testMissingInputThrowsError(testCase)
verifyError(testCase, ...
    @() matlab_code_assist_system_summary('Plot', false), ...
    'matlab_code_assist_system_summary:MissingInput');
end
