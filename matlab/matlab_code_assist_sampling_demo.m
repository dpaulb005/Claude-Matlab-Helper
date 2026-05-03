function result = matlab_code_assist_sampling_demo(f_signal, fs, duration, varargin)
%MATLAB_CODE_ASSIST_SAMPLING_DEMO Visualize sampling, aliasing, and reconstruction.
%
% Demonstrates the effect of sampling rate on a signal, showing:
%   - Dense analog-like waveform
%   - Sampled discrete points
%   - FFT magnitude spectrum comparison (analog vs sampled)
%   - Aliasing warning when fs < 2*f_signal (Nyquist violated)
%
% Usage:
%   result = matlab_code_assist_sampling_demo(f_signal, fs, duration)
%   result = matlab_code_assist_sampling_demo(f_signal, fs, duration, 'Title', 'My Demo')
%   result = matlab_code_assist_sampling_demo(f_signal, fs, duration, 'SignalFn', @(t) sin(2*pi*5*t) + 0.5*sin(2*pi*12*t))
%
% Inputs:
%   f_signal - primary signal frequency in Hz (used for Nyquist warning)
%   fs       - sample rate in Hz
%   duration - signal duration in seconds
%
% Optional name-value pairs:
%   'Title'    - string title for the figure (default: 'Sampling Demo')
%   'SignalFn' - function handle @(t) ... defining the analog signal
%                Default: pure sinusoid at f_signal Hz
%   'OverRate' - dense analog oversampling rate multiplier (default: 200)
%
% Output struct fields:
%   fs              - sample rate used
%   f_signal        - input signal frequency
%   nyquist         - Nyquist rate (2 * f_signal)
%   aliasing        - true if fs < nyquist
%   alias_freq      - apparent aliased frequency when aliasing is true, else NaN
%   t_analog        - dense time axis used for analog approximation
%   x_analog        - analog signal values
%   t_sampled       - sampled time points
%   x_sampled       - sampled signal values
%   f_axis_analog   - frequency axis for analog FFT
%   mag_analog      - magnitude spectrum of analog signal
%   f_axis_sampled  - frequency axis for sampled FFT
%   mag_sampled     - magnitude spectrum of sampled signal

if nargin < 3
    error('matlab_code_assist_sampling_demo:MissingInputs', ...
        'Provide f_signal, fs, and duration. Example: matlab_code_assist_sampling_demo(5, 8, 1)');
end

if f_signal <= 0
    error('matlab_code_assist_sampling_demo:InvalidFrequency', ...
        'f_signal must be positive (Hz).');
end
if fs <= 0
    error('matlab_code_assist_sampling_demo:InvalidSampleRate', ...
        'fs must be positive (Hz).');
end
if duration <= 0
    error('matlab_code_assist_sampling_demo:InvalidDuration', ...
        'duration must be positive (seconds).');
end

% --- Parse optional arguments ---
p = inputParser();
addParameter(p, 'Title',    'Sampling Demo', @(v) ischar(v) || isstring(v));
addParameter(p, 'SignalFn', [],              @(v) isempty(v) || isa(v, 'function_handle'));
addParameter(p, 'OverRate', 200,             @(v) isnumeric(v) && v >= 10);
parse(p, varargin{:});

figTitle = string(p.Results.Title);
signalFn = p.Results.SignalFn;
overRate = p.Results.OverRate;

if isempty(signalFn)
    signalFn = @(t) sin(2 * pi * f_signal * t);
end

% --- Build analog (dense) signal ---
fs_analog   = overRate * max(fs, f_signal * 4);
t_analog    = 0 : 1/fs_analog : duration;
x_analog    = signalFn(t_analog);

% --- Build sampled signal ---
t_sampled   = 0 : 1/fs : duration;
x_sampled   = signalFn(t_sampled);

% --- Nyquist and aliasing analysis ---
nyquist        = 2 * f_signal;
aliasing       = fs < nyquist;
alias_freq     = NaN;
if aliasing
    % Apparent alias: frequency folded around fs/2
    alias_freq = abs(f_signal - round(f_signal / fs) * fs);
end

% --- FFT of analog signal ---
N_analog       = numel(x_analog);
Y_analog       = fft(x_analog) / N_analog;
f_axis_analog  = (0:N_analog-1) * (fs_analog / N_analog);
half_a         = 1 : floor(N_analog/2);
f_axis_analog  = f_axis_analog(half_a);
mag_analog     = 2 * abs(Y_analog(half_a));

% --- FFT of sampled signal ---
N_sampled      = numel(x_sampled);
Y_sampled      = fft(x_sampled) / N_sampled;
f_axis_sampled = (0:N_sampled-1) * (fs / N_sampled);
half_s         = 1 : floor(N_sampled/2);
f_axis_sampled = f_axis_sampled(half_s);
mag_sampled    = 2 * abs(Y_sampled(half_s));

% --- Plot ---
figure('Name', char(figTitle), 'NumberTitle', 'off');

% Panel 1: analog waveform + sampled points
subplot(3, 1, 1);
plot(t_analog, x_analog, 'b-', 'LineWidth', 1.2, 'DisplayName', 'Analog');
hold on;
stem(t_sampled, x_sampled, 'r', 'MarkerSize', 5, 'LineWidth', 1.1, ...
    'DisplayName', sprintf('Sampled at f_s = %g Hz', fs));
hold off;
legend('Location', 'best');
xlabel('t (s)'); ylabel('Amplitude'); grid on;
if aliasing
    title(sprintf('⚠ ALIASING — f_{signal} = %g Hz, f_s = %g Hz  (Nyquist requires ≥ %g Hz)', ...
        f_signal, fs, nyquist), 'Color', [0.8 0.2 0]);
else
    title(sprintf('Sampling — f_{signal} = %g Hz, f_s = %g Hz  (No Aliasing)', ...
        f_signal, fs));
end

% Panel 2: FFT of analog
subplot(3, 1, 2);
plot(f_axis_analog, mag_analog, 'b-', 'LineWidth', 1.2);
xlabel('Frequency (Hz)'); ylabel('|X(f)|'); grid on;
title('Spectrum — Analog Signal (dense)');
xlim([0, max(f_axis_analog)]);

% Panel 3: FFT of sampled + aliasing marker
subplot(3, 1, 3);
stem(f_axis_sampled, mag_sampled, 'r', 'MarkerSize', 4, 'LineWidth', 1.1);
hold on;
if aliasing && ~isnan(alias_freq)
    xline(alias_freq, 'k--', sprintf('Alias ≈ %g Hz', alias_freq), ...
        'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.4);
end
xline(fs/2, 'm--', sprintf('f_s/2 = %g Hz', fs/2), ...
    'LabelVerticalAlignment', 'bottom');
hold off;
xlabel('Frequency (Hz)'); ylabel('|X_s(f)|'); grid on;
title(sprintf('Spectrum — Sampled Signal (f_s = %g Hz)', fs));
xlim([0, fs/2 * 1.2]);

if aliasing
    sgtitle(figTitle + sprintf(' — ⚠ Aliasing: apparent freq ≈ %g Hz', alias_freq), ...
        'Color', [0.8 0.2 0]);
else
    sgtitle(figTitle + ' — No Aliasing Detected');
end

% --- Build result struct ---
result = struct( ...
    'fs',             fs,            ...
    'f_signal',       f_signal,      ...
    'nyquist',        nyquist,       ...
    'aliasing',       aliasing,      ...
    'alias_freq',     alias_freq,    ...
    't_analog',       t_analog,      ...
    'x_analog',       x_analog,      ...
    't_sampled',      t_sampled,     ...
    'x_sampled',      x_sampled,     ...
    'f_axis_analog',  f_axis_analog, ...
    'mag_analog',     mag_analog,    ...
    'f_axis_sampled', f_axis_sampled,...
    'mag_sampled',    mag_sampled);
end
