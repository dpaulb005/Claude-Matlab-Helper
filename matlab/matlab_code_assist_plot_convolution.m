function result = matlab_code_assist_plot_convolution(t, x, h, varargin)
%MATLAB_CODE_ASSIST_PLOT_CONVOLUTION Visualize convolution of two discrete-time signals.
%
% Computes and plots y(t) = x(t) * h(t) (linear convolution), showing:
%   - x(t): first input signal
%   - h(t): second input signal (impulse response)
%   - h(t0-tau): time-reversed and shifted version at the mid-overlap point
%   - y(t): convolution output
%
% Usage:
%   result = matlab_code_assist_plot_convolution(t, x, h)
%   result = matlab_code_assist_plot_convolution(t, x, h, 'Title', 'My Convolution')
%   result = matlab_code_assist_plot_convolution(t, x, h, 'ShiftPoint', 0.5)
%
% Inputs:
%   t  - time axis vector for both x and h (uniform spacing assumed)
%   x  - signal values at each point in t
%   h  - impulse response values at each point in t
%
% Optional name-value pairs:
%   'Title'      - string, title prefix for the figure (default: 'Convolution')
%   'ShiftPoint' - scalar t0 value to snapshot h(t0-tau); defaults to midpoint
%   'Stem'       - true/false, use stem plots instead of stairs (default: false)
%
% Output struct fields:
%   t_out  - time axis of the convolution output
%   y      - convolution output values
%   dt     - time step
%   n_x    - length of x
%   n_h    - length of h
%   n_y    - length of y
%   aliased_warning - true if signals appear to overlap ambiguously

if nargin < 3
    error('matlab_code_assist_plot_convolution:MissingInputs', ...
        'Provide t, x, and h. Example: matlab_code_assist_plot_convolution(t, x, h)');
end

t   = t(:)';
x   = x(:)';
h   = h(:)';

if numel(t) ~= numel(x)
    error('matlab_code_assist_plot_convolution:LengthMismatch', ...
        't and x must have the same number of elements.');
end
if numel(t) ~= numel(h)
    error('matlab_code_assist_plot_convolution:LengthMismatch', ...
        't and h must have the same number of elements.');
end

dt = mean(diff(t));
if abs(dt) < 1e-14
    error('matlab_code_assist_plot_convolution:ZeroTimeStep', ...
        't must be a non-degenerate increasing time vector.');
end

% --- Parse optional arguments ---
p = inputParser();
addParameter(p, 'Title',      'Convolution', @(v) ischar(v) || isstring(v));
addParameter(p, 'ShiftPoint', NaN,           @isnumeric);
addParameter(p, 'Stem',       false,         @islogical);
parse(p, varargin{:});

figTitle   = string(p.Results.Title);
shiftPoint = p.Results.ShiftPoint;
useStem    = p.Results.Stem;

% --- Compute convolution ---
y    = conv(x, h) * dt;           % scale by dt for continuous-time analogy
n_y  = numel(y);
t_out = t(1)*2 + (0:n_y-1) * dt; % output time axis starting at 2*t(1)

% --- Choose shift snapshot point ---
if isnan(shiftPoint)
    midIdx = round(n_y / 2);
    shiftPoint = t_out(max(1, min(midIdx, n_y)));
end

% Build h(t0 - tau) over the tau axis t
tau      = t;
h_flipped_shifted = interp1(t, h, shiftPoint - tau, 'linear', 0);

% --- Detect potential aliasing/wraparound flag ---
x_support = sum(abs(x) > 1e-10 * max(abs(x)+eps));
h_support = sum(abs(h) > 1e-10 * max(abs(h)+eps));
aliased_warning = (x_support + h_support) > numel(t);

% --- Plot ---
figure('Name', char(figTitle), 'NumberTitle', 'off');

plotFn = @localPlotLine;
if useStem
    plotFn = @localPlotStem;
end

subplot(4, 1, 1);
plotFn(t, x, 'b');
title(figTitle + " — x(t): Input Signal");
xlabel('t'); ylabel('x(t)'); grid on;

subplot(4, 1, 2);
plotFn(t, h, 'r');
title("h(t): Impulse Response");
xlabel('t'); ylabel('h(t)'); grid on;

subplot(4, 1, 3);
plotFn(tau, h_flipped_shifted, 'm');
xline(shiftPoint, 'k--', sprintf('t_0 = %.2g', shiftPoint), ...
    'LabelVerticalAlignment', 'bottom');
title(sprintf("h(t_0 - \\tau) at t_0 = %.4g  [time-reversed & shifted]", shiftPoint));
xlabel('\tau'); ylabel('h(t_0 - \tau)'); grid on;

subplot(4, 1, 4);
plotFn(t_out, y, 'g');
title("y(t) = x(t) * h(t)  [Convolution Output]");
xlabel('t'); ylabel('y(t)'); grid on;

if aliased_warning
    sgtitle(figTitle + " ⚠ Signal supports may exceed time window — consider longer t", ...
        'Color', [0.8 0.4 0]);
else
    sgtitle(figTitle);
end

% --- Build result struct ---
result = struct( ...
    't_out',          t_out,          ...
    'y',              y,              ...
    'dt',             dt,             ...
    'n_x',            numel(x),       ...
    'n_h',            numel(h),       ...
    'n_y',            n_y,            ...
    'aliased_warning', aliased_warning);
end

% -----------------------------------------------------------------------
function localPlotLine(t, y, color)
plot(t, y, color, 'LineWidth', 1.4);
end

function localPlotStem(t, y, color)
stem(t, y, color, 'MarkerSize', 4, 'LineWidth', 1.2);
end
