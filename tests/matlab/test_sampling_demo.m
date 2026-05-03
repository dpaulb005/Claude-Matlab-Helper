function tests = test_sampling_demo
%TEST_SAMPLING_DEMO Function tests for matlab_code_assist_sampling_demo.
tests = functiontests(localfunctions);
end

function setup(~)
projectDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectDir, 'matlab'));
end

function testResultStructHasRequiredFields(testCase)
result = matlab_code_assist_sampling_demo(5, 50, 0.5);
close all;

required = {'fs','f_signal','nyquist','aliasing','alias_freq', ...
            't_analog','x_analog','t_sampled','x_sampled', ...
            'f_axis_analog','mag_analog','f_axis_sampled','mag_sampled'};
for k = 1:numel(required)
    verifyTrue(testCase, isfield(result, required{k}), ...
        ['Missing field: ' required{k}]);
end
end

function testNyquistRateIsCorrect(testCase)
result = matlab_code_assist_sampling_demo(10, 100, 0.5);
close all;

verifyEqual(testCase, result.nyquist, 20);
end

function testAliasingDetectedWhenFsBelowNyquist(testCase)
result = matlab_code_assist_sampling_demo(10, 15, 0.5);
close all;

verifyTrue(testCase, result.aliasing);
verifyFalse(testCase, isnan(result.alias_freq));
end

function testNoAliasingWhenFsAboveNyquist(testCase)
result = matlab_code_assist_sampling_demo(10, 50, 0.5);
close all;

verifyFalse(testCase, result.aliasing);
verifyTrue(testCase, isnan(result.alias_freq));
end

function testCustomSignalFunctionIsUsed(testCase)
myFn = @(t) cos(2*pi*5*t);
result = matlab_code_assist_sampling_demo(5, 100, 0.2, 'SignalFn', myFn);
close all;

verifyGreaterThan(testCase, numel(result.x_sampled), 0);
end

function testInvalidInputsThrowErrors(testCase)
verifyError(testCase, ...
    @() matlab_code_assist_sampling_demo(-5, 50, 1), ...
    'matlab_code_assist_sampling_demo:InvalidFrequency');
verifyError(testCase, ...
    @() matlab_code_assist_sampling_demo(5, -10, 1), ...
    'matlab_code_assist_sampling_demo:InvalidSampleRate');
verifyError(testCase, ...
    @() matlab_code_assist_sampling_demo(5, 50, -1), ...
    'matlab_code_assist_sampling_demo:InvalidDuration');
end
