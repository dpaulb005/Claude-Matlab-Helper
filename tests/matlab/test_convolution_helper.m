function tests = test_convolution_helper
%TEST_CONVOLUTION_HELPER Function tests for matlab_code_assist_plot_convolution.
tests = functiontests(localfunctions);
end

function setup(~)
projectDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectDir, 'matlab'));
end

function testOutputSizeIsCorrectForRectangularPulses(testCase)
t = 0:0.1:1;
x = ones(size(t));
h = ones(size(t));

result = matlab_code_assist_plot_convolution(t, x, h);
close all;

expected_n_y = numel(x) + numel(h) - 1;
verifyEqual(testCase, result.n_y, expected_n_y);
end

function testResultStructHasRequiredFields(testCase)
t = 0:0.1:0.5;
x = [1 0 1 0 1 0];
h = [1 1 0 0 0 0];

result = matlab_code_assist_plot_convolution(t, x, h);
close all;

verifyTrue(testCase, isfield(result, 't_out'));
verifyTrue(testCase, isfield(result, 'y'));
verifyTrue(testCase, isfield(result, 'dt'));
verifyTrue(testCase, isfield(result, 'n_x'));
verifyTrue(testCase, isfield(result, 'n_h'));
verifyTrue(testCase, isfield(result, 'n_y'));
verifyTrue(testCase, isfield(result, 'aliased_warning'));
end

function testMismatchedLengthsThrowsError(testCase)
t = 0:0.1:1;
x = ones(1, 5);
h = ones(1, 11);

verifyError(testCase, ...
    @() matlab_code_assist_plot_convolution(t, x, h), ...
    'matlab_code_assist_plot_convolution:LengthMismatch');
end

function testDtIsCorrectForUniformTimeAxis(testCase)
t = 0:0.05:1;
x = ones(size(t));
h = ones(size(t));

result = matlab_code_assist_plot_convolution(t, x, h);
close all;

verifyEqual(testCase, result.dt, 0.05, 'AbsTol', 1e-10);
end
