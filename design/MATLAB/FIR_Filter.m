clear;
close all;
clc;

%% Input Signal
Fs = 44100;
Ts = 1/Fs;
t = 0:Ts:1-Ts;

%% Specs
wp = 0.25*pi;
ws = 0.35*pi;
wc = (wp + ws) / 2;
fc = (wc / (2*pi)) * Fs;

f1 = fc * 0.2;
f2 = fc * 5;

x = sin(2*pi*f1*t);%% + sin(2*pi*f2*t);


%% Filter Design
Ap = 0.1;
As = 50;
delta_w = ws - wp;
delta_p = (10^(Ap/20) - 1) / (10^(Ap/20) + 1);
delta_s = (1 + delta_p) / (10^(As/20));
delta = min(delta_p, delta_s);
A = -20 * log10(delta);

%% Design Using Regular LUT Window
[alpha, L, w] = Window(A, delta_w, 0);
n = 0:L-1;
hd = sin(wc * (n - alpha)) ./ (pi * (n - alpha));
hd(alpha + 1) = wc / pi; % Handle the singularity at n = alpha
h = hd .* w';

figure;
stem(n, h, 'filled');
title('Impulse Response (h(n))');
xlabel('n');
ylabel('Amplitude');
grid on;

figure;
freqz(h, 1, 1024);
title('Frequency Response');
xlabel('Normalized Frequency (\times\pi rad/sample)');
ylabel('Magnitude (dB)');
grid on;

%% Design Using Kaiser Window
[alpha, L, w] = Window(A, delta_w, 1);
n = 0:L-1;
hd = sin(wc * (n - alpha)) ./ (pi * (n - alpha));
hd(alpha + 1) = wc / pi; % Handle the singularity at n = alpha
h = hd .* w';


%% Output coefficients to file as binary values
z = [];
fileID = fopen('coeffs.txt', 'w');
fprintf(fileID, '{'); 
for i = 1:length(h)
    coeff = h(i) * 2^15; 
    if coeff >= 0
        coeff = round(coeff);
    else
        coeff = int16(1 + bitcmp(int16(round(coeff)), 'int16')); % Two’s complement
    end
    if i == length(h)
        fprintf(fileID, '%d', coeff);
    else
        fprintf(fileID, '%d, ', coeff);
    end
    z(i) = coeff;
end
fprintf(fileID, '}'); % End with the closing curly brace
fclose(fileID);

figure;
stem(n, h, 'filled');
title('Impulse Response (h(n)) with Kaiser Window');
xlabel('n');
ylabel('Amplitude');
grid on;

figure;
freqz(h, 1, 1024);
title('Frequency Response (Kaiser Window)');
xlabel('Normalized Frequency (\times\pi rad/sample)');
ylabel('Magnitude (dB)');
grid on;

%% Filter the Signal
y = conv(x, h);

figure;
subplot(2, 1, 1);
plot(t, x);
title('Input Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(2, 1, 2);
plot(t, y(1:length(t)));
title('Output Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;
