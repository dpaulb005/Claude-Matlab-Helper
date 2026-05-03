function tests = test_problem_context
%TEST_PROBLEM_CONTEXT Function tests for matlab_code_assist_problem_context.
tests = functiontests(localfunctions);
end

function setup(~)
projectDir = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(projectDir, "matlab"));
matlab_code_assist_problem_log("clear");
matlab_code_assist_problem_state("clear");
end

function teardown(~)
matlab_code_assist_problem_log("clear");
matlab_code_assist_problem_state("clear");
end

function testProblemContextIncludesActiveProblemHistory(testCase)
matlab_code_assist_problem_log("append", "1a", "What is convolution?", "A weighted overlap integral.");
matlab_code_assist_problem_log("append", "1a", "What changes in discrete time?", "A weighted sum.");

context = matlab_code_assist_problem_context("Continue problem 1a", "1a");

verifyNotEmpty(testCase, context);
verifyNotEmpty(testCase, strfind(context, "Problem 1a session history:"));
verifyNotEmpty(testCase, strfind(context, "What is convolution?"));
end

function testProblemContextIgnoresUnknownProblems(testCase)
context = matlab_code_assist_problem_context("Switch to problem 9z", "");

verifyEqual(testCase, context, "");
end
