function tests = test_fourier_demo
%TEST_FOURIER_DEMO Function tests for matlab_code_assist_fourier_demo.
tests = functiontests(localfunctions);
end

function setup(~)
projectDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectDir, 'matlab'));
end

function testSquareWaveResultHasRequiredFields(testCase)
result = matlab_code_assist_fourier_demo('Waveform','square','N',5,'T',1,'ShowSpec',false);
close all;
required = {'t','x_target','x_recon','a','b','N','T','rmse'};
for k = 1:numel(required)
    verifyTrue(testCase, isfield(result, required{k}), ['Missing: ' required{k}]);
end
end

function testReconstructionLengthMatchesTimeAxis(testCase)
result = matlab_code_assist_fourier_demo('Waveform','square','N',5,'T',1,'ShowSpec',false);
close all;
verifyEqual(testCase, numel(result.x_recon), numel(result.t));
end

function testRmseDecreasesWithMoreHarmonics(testCase)
r1 = matlab_code_assist_fourier_demo('Waveform','square','N',3,'T',1,'ShowSpec',false);
close all;
r2 = matlab_code_assist_fourier_demo('Waveform','square','N',15,'T',1,'ShowSpec',false);
close all;
verifyLessThan(testCase, r2.rmse, r1.rmse);
end

function testCoeffFnPathWorks(testCase)
% Square wave via coefficient function
fn = @(n) [0, (mod(n,2)==1)*4/(n*pi+eps*(n==0))];
result = matlab_code_assist_fourier_demo('CoeffFn', fn, 'N', 7, 'T', 1, 'ShowSpec', false);
close all;
verifyEqual(testCase, result.N, 7);
verifyEqual(testCase, numel(result.a), 8);
end

function testSawtoothAndTriangleWaveformsDontError(testCase)
matlab_code_assist_fourier_demo('Waveform','sawtooth','N',5,'T',1,'ShowSpec',false);
close all;
matlab_code_assist_fourier_demo('Waveform','triangle','N',5,'T',1,'ShowSpec',false);
close all;
verifyTrue(testCase, true);
end

function testUnknownWaveformThrowsError(testCase)
verifyError(testCase, ...
    @() matlab_code_assist_fourier_demo('Waveform','bananawave','N',5,'ShowSpec',false), ...
    'matlab_code_assist_fourier_demo:UnknownWaveform');
end
