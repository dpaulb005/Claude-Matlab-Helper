function code = clr(target)
%CLR Fast prerecorded MATLAB fallback snippet generator.
%
% Examples:
%   clr
%   clr("command")
%   clr("editor")

if nargin < 1 || strlength(string(target)) == 0
    target = "command";
else
    target = lower(string(target));
end

snippets = {
    [
        "fs = 500;"
        "t = 0:1/fs:2;"
        "x1 = sin(2*pi*5*t);"
        "x2 = 0.6*cos(2*pi*12*t + pi/6);"
        "x3 = 0.3*sin(2*pi*20*t);"
        "x = x1 + x2 + x3;"
        "noise = 0.05*randn(size(t));"
        "xNoisy = x + noise;"
        "win = hann(numel(xNoisy))';"
        "xWin = xNoisy .* win;"
        "N = numel(xWin);"
        "X = fftshift(fft(xWin));"
        "f = linspace(-fs/2, fs/2, N);"
        "magX = abs(X)/N;"
        "figure;"
        "subplot(3,1,1);"
        "plot(t, x, 'LineWidth', 1.2);"
        "grid on;"
        "title('Clean composite signal');"
        "xlabel('Time (s)');"
        "ylabel('Amplitude');"
        "subplot(3,1,2);"
        "plot(t, xNoisy, 'LineWidth', 1.0);"
        "grid on;"
        "title('Noisy signal');"
        "xlabel('Time (s)');"
        "ylabel('Amplitude');"
        "subplot(3,1,3);"
        "plot(f, magX, 'LineWidth', 1.2);"
        "grid on; title('Magnitude spectrum'); xlabel('Frequency (Hz)'); ylabel('|X(f)|');"
    ]
    [
        "n = 0:40;"
        "x = (0.85).^n;"
        "u = double(n >= 0);"
        "x = x .* u;"
        "h = [1 0.5 0.25 0.125];"
        "y = conv(x, h);"
        "ny = 0:numel(y)-1;"
        "energyX = sum(abs(x).^2);"
        "energyH = sum(abs(h).^2);"
        "energyY = sum(abs(y).^2);"
        "figure;"
        "subplot(3,1,1);"
        "stem(n, x, 'filled');"
        "grid on;"
        "title('Input sequence x[n]');"
        "xlabel('n');"
        "ylabel('x[n]');"
        "subplot(3,1,2);"
        "stem(0:numel(h)-1, h, 'filled');"
        "grid on;"
        "title('Impulse response h[n]');"
        "xlabel('n');"
        "ylabel('h[n]');"
        "subplot(3,1,3);"
        "stem(ny, y, 'filled');"
        "grid on;"
        "title('Convolution output y[n]');"
        "xlabel('n');"
        "ylabel('y[n]');"
        "disp(['Energy of x[n]: ' num2str(energyX)]);"
        "disp(['Energy of h[n]: ' num2str(energyH)]);"
        "disp(['Energy of y[n]: ' num2str(energyY)]);"
    ]
    [
        "w = -40:0.05:40;"
        "H = 1 ./ (1 + 1j*w/8);"
        "magH = abs(H);"
        "phaseH = unwrap(angle(H));"
        "groupDelay = -gradient(phaseH, w);"
        "figure;"
        "subplot(3,1,1);"
        "plot(w, magH, 'LineWidth', 1.2);"
        "grid on;"
        "title('Magnitude response');"
        "xlabel('\omega (rad/s)');"
        "ylabel('|H(j\omega)|');"
        "subplot(3,1,2);"
        "plot(w, phaseH, 'LineWidth', 1.2);"
        "grid on;"
        "title('Unwrapped phase response');"
        "xlabel('\omega (rad/s)');"
        "ylabel('\angle H(j\omega)');"
        "subplot(3,1,3);"
        "plot(w, groupDelay, 'LineWidth', 1.2);"
        "grid on;"
        "title('Approximate group delay');"
        "xlabel('\omega (rad/s)');"
        "ylabel('-d\phi/d\omega');"
        "wc = 8;"
        "idx = find(abs(w) <= wc, 1, 'last');"
        "disp(['Approximate bandwidth: ' num2str(wc) ' rad/s']);"
        "disp(['Magnitude at cutoff: ' num2str(magH(idx))]);"
        "disp(['Phase at cutoff: ' num2str(phaseH(idx))]);"
    ]
    [
        "fs1 = 120;"
        "fs2 = 35;"
        "t1 = 0:1/fs1:1;"
        "t2 = 0:1/fs2:1;"
        "x1 = sin(2*pi*18*t1);"
        "x2 = sin(2*pi*18*t2);"
        "figure;"
        "subplot(3,1,1);"
        "plot(t1, x1, 'LineWidth', 1.2);"
        "grid on;"
        "title('Continuous-time proxy sampled at 120 Hz');"
        "xlabel('Time (s)');"
        "ylabel('Amplitude');"
        "subplot(3,1,2);"
        "stem(t2, x2, 'filled');"
        "grid on;"
        "title('Samples at 35 Hz');"
        "xlabel('Time (s)');"
        "ylabel('Amplitude');"
        "N = numel(x2);"
        "X2 = fftshift(abs(fft(x2)));"
        "f2 = linspace(-fs2/2, fs2/2, N);"
        "subplot(3,1,3);"
        "plot(f2, X2, 'LineWidth', 1.2);"
        "grid on;"
        "title('Spectrum showing aliasing');"
        "xlabel('Frequency (Hz)');"
        "ylabel('|X(f)|');"
        "fAlias = abs(18 - round(18/fs2)*fs2);"
        "disp(['True tone frequency: 18 Hz']);"
        "disp(['Sampling frequency: ' num2str(fs2) ' Hz']);"
        "disp(['Observed alias frequency: ' num2str(fAlias) ' Hz']);"
    ]
    [
        "A = [0 1; -6 -5];"
        "B = [0; 1];"
        "C = [1 0];"
        "D = 0;"
        "sys = ss(A, B, C, D);"
        "t = 0:0.01:8;"
        "[yStep, tStep] = step(sys, t);"
        "[yImpulse, tImpulse] = impulse(sys, t);"
        "eigA = eig(A);"
        "dcGain = dcgain(sys);"
        "figure;"
        "subplot(2,1,1);"
        "plot(tStep, yStep, 'LineWidth', 1.3);"
        "grid on;"
        "title('Step response of second-order system');"
        "xlabel('Time (s)');"
        "ylabel('y_{step}(t)');"
        "subplot(2,1,2);"
        "plot(tImpulse, yImpulse, 'LineWidth', 1.3);"
        "grid on;"
        "title('Impulse response of second-order system');"
        "xlabel('Time (s)');"
        "ylabel('h(t)');"
        "disp('System matrix A:');"
        "disp(A);"
        "disp('Eigenvalues of A:');"
        "disp(eigA);"
        "disp(['DC gain: ' num2str(dcGain)]);"
        "disp(['Stable system? ' num2str(all(real(eigA) < 0))]);"
    ]
};

index = randi(numel(snippets));
code = strjoin(snippets{index}, newline);

switch target
    case "command"
        assignin("base", "matlabCodeAssistLast", string(code));
        fprintf("\n%s\n\n", code);
    case "editor"
        matlab_code_assist_apply_to_editor(code);
    otherwise
        error("clr:InvalidTarget", "Target must be 'command' or 'editor'.");
end
end
