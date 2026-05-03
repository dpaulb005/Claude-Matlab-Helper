function result = matlab_code_assist_fourier_demo(varargin)
%MATLAB_CODE_ASSIST_FOURIER_DEMO Fourier series reconstruction explorer.
%
% Computes and plots partial Fourier series reconstructions of a periodic signal,
% showing how adding harmonics builds up toward the target waveform.
%
% Usage forms:
%   % Provide coefficient function a_n, b_n and reconstruct up to N harmonics:
%   result = matlab_code_assist_fourier_demo('CoeffFn', @(n) [2/(n*pi) 0], 'N', 10, 'T', 1)
%
%   % Provide precomputed a and b arrays (index 1 = DC/n=0, index 2 = n=1, ...):
%   result = matlab_code_assist_fourier_demo('a', a_coeffs, 'b', b_coeffs, 'T', 1)
%
%   % Use a built-in waveform: 'square', 'sawtooth', 'triangle'
%   result = matlab_code_assist_fourier_demo('Waveform', 'square', 'N', 15, 'T', 1)
%
% Optional name-value pairs:
%   'N'        - number of harmonics (default: 10)
%   'T'        - period in seconds (default: 2*pi)
%   'Points'   - time-axis resolution points (default: 1000)
%   'Title'    - figure title string
%   'ShowSpec' - true (default) to show magnitude/phase stem plots
%
% Output struct fields:
%   t         - time axis
%   x_target  - target/reference waveform (if Waveform specified, else empty)
%   x_recon   - final reconstruction using N harmonics
%   a         - cosine coefficients [a0, a1, ..., aN]
%   b         - sine coefficients   [0,  b1, ..., bN]
%   N         - number of harmonics used
%   T         - period
%   rmse      - RMS error between target and reconstruction (NaN if no target)

p = inputParser();
addParameter(p, 'CoeffFn',  [],        @(v) isempty(v) || isa(v, 'function_handle'));
addParameter(p, 'a',        [],        @isnumeric);
addParameter(p, 'b',        [],        @isnumeric);
addParameter(p, 'Waveform', '',        @(v) ischar(v) || isstring(v));
addParameter(p, 'N',        10,        @(v) isnumeric(v) && v >= 1);
addParameter(p, 'T',        2*pi,      @(v) isnumeric(v) && v > 0);
addParameter(p, 'Points',   1000,      @(v) isnumeric(v) && v >= 10);
addParameter(p, 'Title',    'Fourier Reconstruction', @(v) ischar(v) || isstring(v));
addParameter(p, 'ShowSpec', true,      @islogical);
parse(p, varargin{:});

N       = round(p.Results.N);
T       = p.Results.T;
pts     = p.Results.Points;
figTitle = string(p.Results.Title);
showSpec = p.Results.ShowSpec;
waveform = lower(strtrim(string(p.Results.Waveform)));
coeffFn  = p.Results.CoeffFn;
a_in     = p.Results.a(:)';
b_in     = p.Results.b(:)';

omega0 = 2*pi / T;
t = linspace(-T/2, T/2, pts);

% --- Determine coefficients ---
a = zeros(1, N+1);  % a(1)=a0, a(k+1)=a_k
b = zeros(1, N+1);  % b(1)=0 (DC sine term is 0), b(k+1)=b_k

x_target = [];

if strlength(waveform) > 0 && ~any(waveform == ["", "none"])
    % Built-in waveforms — compute coefficients analytically
    switch char(waveform)
        case 'square'
            % x(t) = 4/pi * sum_{k odd} sin(k*omega0*t)/k
            figTitle = figTitle + " (Square Wave)";
            a(1) = 0;
            for k = 1:N
                if mod(k,2) == 1
                    b(k+1) = 4/(k*pi);
                end
            end
            x_target = sign(sin(omega0*t));
            x_target(x_target == 0) = 1;

        case 'sawtooth'
            % x(t) = -2/pi * sum_{k=1}^N (-1)^k * sin(k*omega0*t)/k
            figTitle = figTitle + " (Sawtooth Wave)";
            a(1) = 0;
            for k = 1:N
                b(k+1) = -2/pi * ((-1)^k) / k;
            end
            x_target = 2*(t/T - floor(t/T + 0.5));

        case 'triangle'
            % x(t) = 8/pi^2 * sum_{k odd} (-1)^((k-1)/2) * sin(k*omega0*t)/k^2
            figTitle = figTitle + " (Triangle Wave)";
            a(1) = 0;
            for k = 1:N
                if mod(k,2) == 1
                    b(k+1) = (8/(pi^2)) * ((-1)^((k-1)/2)) / k^2;
                end
            end
            x_target = 2*abs(2*(t/T - floor(t/T + 0.5))) - 1;

        otherwise
            error('matlab_code_assist_fourier_demo:UnknownWaveform', ...
                'Waveform must be ''square'', ''sawtooth'', or ''triangle''. Got: %s', char(waveform));
    end

elseif ~isempty(coeffFn)
    % User-supplied function handle: coeffFn(n) returns [a_n, b_n]
    c = coeffFn(0);
    a(1) = c(1);
    for k = 1:N
        c = coeffFn(k);
        a(k+1) = c(1);
        b(k+1) = c(2);
    end

elseif ~isempty(a_in) || ~isempty(b_in)
    % User-supplied arrays
    na = numel(a_in);
    nb = numel(b_in);
    a(1:min(na, N+1)) = a_in(1:min(na, N+1));
    b(1:min(nb, N+1)) = b_in(1:min(nb, N+1));

else
    error('matlab_code_assist_fourier_demo:MissingInput', ...
        'Provide CoeffFn, a/b arrays, or a Waveform name.');
end

% --- Build reconstruction ---
x_recon = a(1)/2 * ones(size(t));  % a0/2 is the DC term
for k = 1:N
    x_recon = x_recon + a(k+1)*cos(k*omega0*t) + b(k+1)*sin(k*omega0*t);
end

% --- RMSE ---
if ~isempty(x_target)
    rmse = sqrt(mean((x_recon - x_target).^2));
else
    rmse = NaN;
end

% --- Plot ---
if showSpec
    figure('Name', char(figTitle), 'NumberTitle', 'off');
    nrows = 3;
else
    figure('Name', char(figTitle), 'NumberTitle', 'off');
    nrows = 2;
end

% Panel 1: target vs reconstruction
subplot(nrows, 1, 1);
if ~isempty(x_target)
    plot(t, x_target, 'k--', 'LineWidth', 1.0, 'DisplayName', 'Target');
    hold on;
end
plot(t, x_recon, 'b-', 'LineWidth', 1.4, 'DisplayName', sprintf('Reconstruction (N=%d)', N));
if ~isempty(x_target); hold off; end
xlabel('t (s)'); ylabel('Amplitude'); grid on;
legend('Location', 'best');
if ~isnan(rmse)
    title(sprintf('%s  |  N = %d harmonics  |  RMSE = %.4f', char(figTitle), N, rmse));
else
    title(sprintf('%s  |  N = %d harmonics', char(figTitle), N));
end

% Panel 2: harmonic build-up (show a few partial sums)
subplot(nrows, 1, 2);
x_partial = a(1)/2 * ones(size(t));
nShow = min(N, 5);
step  = max(1, floor(N / nShow));
cmap  = lines(nShow);
idx   = 0;
for k = 1:N
    x_partial = x_partial + a(k+1)*cos(k*omega0*t) + b(k+1)*sin(k*omega0*t);
    if mod(k, step) == 0 || k == N
        idx = idx + 1;
        plot(t, x_partial, 'Color', cmap(min(idx,nShow),:), 'LineWidth', 1.0, ...
            'DisplayName', sprintf('N = %d', k));
        hold on;
    end
end
hold off;
xlabel('t (s)'); ylabel('Amplitude'); grid on;
legend('Location', 'best');
title('Partial Sums — Harmonic Build-Up');

% Panel 3: spectrum
if showSpec
    n_idx = 0:N;
    subplot(nrows, 1, 3);
    yyaxis left;
    stem(n_idx, abs(a), 'b', 'MarkerSize', 4, 'LineWidth', 1.1, 'DisplayName', '|a_n|');
    ylabel('|a_n| (cosine)');
    yyaxis right;
    stem(n_idx, abs(b), 'r', 'MarkerSize', 4, 'LineWidth', 1.1, 'DisplayName', '|b_n|');
    ylabel('|b_n| (sine)');
    xlabel('Harmonic n'); grid on;
    title('Coefficient Magnitudes');
    legend('Location', 'best');
end

sgtitle(figTitle);

% --- Build result ---
result = struct( ...
    't',        t,        ...
    'x_target', x_target, ...
    'x_recon',  x_recon,  ...
    'a',        a,        ...
    'b',        b,        ...
    'N',        N,        ...
    'T',        T,        ...
    'rmse',     rmse);
end
