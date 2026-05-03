function result = matlab_code_assist_system_summary(varargin)
%MATLAB_CODE_ASSIST_SYSTEM_SUMMARY Analyse an LTI system for poles, zeros, stability, and response.
%
% Stays within base MATLAB + Symbolic Math Toolbox only.
% Does NOT use Control System Toolbox (tf, bode, step, etc.).
%
% Usage forms:
%   result = matlab_code_assist_system_summary('num', [1], 'den', [1 3 2])
%       Polynomial coefficient vectors: H(s) = num(s) / den(s)
%
%   result = matlab_code_assist_system_summary('expr', '1/(s^2 + 3*s + 2)')
%       Symbolic expression string evaluated with syms s
%
% Optional name-value pairs:
%   'Domain'  - 'continuous' (default) or 'discrete'
%   'Title'   - string title for the figure
%   'Plot'    - true (default) or false — whether to generate a figure
%
% Output struct fields:
%   poles           - pole values (complex double)
%   zeros           - zero values (complex double)
%   stable          - true if BIBO stable
%   stability_reason - short explanation string
%   domain          - 'continuous' or 'discrete'
%   H_sym           - symbolic transfer function (if Symbolic Math Toolbox available)
%   h_time          - symbolic impulse response (if computable)

p = inputParser();
addParameter(p, 'num',    [],          @isnumeric);
addParameter(p, 'den',    [],          @isnumeric);
addParameter(p, 'expr',   '',          @(v) ischar(v) || isstring(v));
addParameter(p, 'Domain', 'continuous',@(v) ischar(v) || isstring(v));
addParameter(p, 'Title',  'System Summary', @(v) ischar(v) || isstring(v));
addParameter(p, 'Plot',   true,        @islogical);
parse(p, varargin{:});

num    = p.Results.num;
den    = p.Results.den;
expr   = strtrim(string(p.Results.expr));
domain = lower(strtrim(string(p.Results.Domain)));
figTitle = string(p.Results.Title);
doPlot = p.Results.Plot;

if ~any(domain == ["continuous", "discrete"])
    error('matlab_code_assist_system_summary:InvalidDomain', ...
        'Domain must be ''continuous'' or ''discrete''.');
end

% --- Determine poles and zeros numerically ---
poles = [];
zs    = [];
H_sym = [];
h_time = [];

if strlength(expr) > 0
    % Symbolic path
    try
        syms s z
        if domain == "discrete"
            H_sym = eval(char(expr));   %#ok<EVLCS>
            [n_sym, d_sym] = numden(H_sym);
            poles = double(solve(d_sym == 0, z));
            zs    = double(solve(n_sym == 0, z));
        else
            H_sym = eval(char(expr));   %#ok<EVLCS>
            [n_sym, d_sym] = numden(H_sym);
            poles = double(solve(d_sym == 0, s));
            zs    = double(solve(n_sym == 0, s));
            try
                h_time = ilaplace(H_sym);
            catch
                h_time = [];
            end
        end
    catch ME
        error('matlab_code_assist_system_summary:SymbolicError', ...
            'Could not parse symbolic expression: %s', ME.message);
    end

elseif ~isempty(num) && ~isempty(den)
    poles = roots(den(:)');
    zs    = roots(num(:)');
    % Build symbolic form if toolbox available
    try
        syms s z
        if domain == "discrete"
            H_sym = poly2sym(num, z) / poly2sym(den, z);
        else
            H_sym = poly2sym(num, s) / poly2sym(den, s);
            try
                h_time = ilaplace(H_sym);
            catch
                h_time = [];
            end
        end
    catch
        H_sym = [];
    end

else
    error('matlab_code_assist_system_summary:MissingInput', ...
        'Provide either ''num''/''den'' coefficient vectors or an ''expr'' string.');
end

% --- Stability analysis ---
stable = false;
stability_reason = '';

if domain == "continuous"
    if isempty(poles)
        stable = true;
        stability_reason = 'No finite poles — trivially stable.';
    elseif all(real(poles) < 0)
        stable = true;
        stability_reason = 'All poles have strictly negative real parts.';
    elseif any(real(poles) > 0)
        stable = false;
        stability_reason = sprintf('Unstable: %d pole(s) in the right half-plane.', sum(real(poles) > 0));
    else
        stable = false;
        stability_reason = 'Marginally stable: pole(s) on imaginary axis (not BIBO stable).';
    end
else
    % Discrete-time: stable if all poles inside unit circle
    mags = abs(poles);
    if isempty(poles)
        stable = true;
        stability_reason = 'No finite poles — trivially stable.';
    elseif all(mags < 1)
        stable = true;
        stability_reason = 'All poles inside the unit circle.';
    elseif any(mags > 1)
        stable = false;
        stability_reason = sprintf('Unstable: %d pole(s) outside unit circle.', sum(mags > 1));
    else
        stable = false;
        stability_reason = 'Marginally stable: pole(s) on unit circle (not BIBO stable).';
    end
end

% --- Print summary to Command Window ---
fprintf('\n=== System Summary (%s-time) ===\n', char(domain));
fprintf('Poles : '); disp(poles.');
fprintf('Zeros : '); disp(zs.');
if stable
    fprintf('Stability : STABLE — %s\n', stability_reason);
else
    fprintf('Stability : UNSTABLE — %s\n', stability_reason);
end
if ~isempty(h_time)
    fprintf('Impulse response h(t) = '); disp(h_time);
end
fprintf('\n');

% --- Plot pole-zero map ---
if doPlot
    figure('Name', char(figTitle), 'NumberTitle', 'off');

    if domain == "continuous"
        % s-plane
        hold on;
        plot(real(poles), imag(poles), 'rx', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Poles');
        if ~isempty(zs)
            plot(real(zs), imag(zs), 'bo', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'Zeros');
        end
        xline(0, 'k--', 'LineWidth', 0.8);
        yline(0, 'k-',  'LineWidth', 0.8);
        xlabel('Real'); ylabel('Imag');
        title(figTitle + sprintf(' — Pole-Zero Map (s-plane)  |  %s', stability_reason));
        legend('Location', 'best');
        grid on; axis equal;
        hold off;
    else
        % z-plane with unit circle
        theta = linspace(0, 2*pi, 360);
        hold on;
        plot(cos(theta), sin(theta), 'k--', 'LineWidth', 0.9, 'DisplayName', 'Unit Circle');
        plot(real(poles), imag(poles), 'rx', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Poles');
        if ~isempty(zs)
            plot(real(zs), imag(zs), 'bo', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'Zeros');
        end
        xline(0, 'k:', 'LineWidth', 0.5);
        yline(0, 'k:', 'LineWidth', 0.5);
        xlabel('Real'); ylabel('Imag');
        title(figTitle + sprintf(' — Pole-Zero Map (z-plane)  |  %s', stability_reason));
        legend('Location', 'best');
        grid on; axis equal;
        hold off;
    end
end

% --- Build result ---
result = struct( ...
    'poles',            poles,            ...
    'zeros',            zs,               ...
    'stable',           stable,           ...
    'stability_reason', stability_reason, ...
    'domain',           char(domain),     ...
    'H_sym',            H_sym,            ...
    'h_time',           h_time);
end
