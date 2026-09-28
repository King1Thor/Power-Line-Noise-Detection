clear;
clc;
close all;

%% Load Talley's spark-only test file
data = load('SPARK_ONLY_001.mat');

iq = data.eventIQ;
fs = data.fs;
fc = data.fc;

%% Basic information
fprintf('Samples: %d\n', length(iq));
fprintf('Sample rate: %.0f Hz\n', fs);
fprintf('Center frequency: %.1f MHz\n', fc/1e6);

%% Time axis
t = (0:length(iq)-1) / fs;

%% I/Q magnitude
mag = abs(iq);

%% Plot first 50 ms
showTime = 0.05;
Nshow = round(showTime * fs);

figure;
plot(t(1:Nshow)*1000, mag(1:Nshow));
xlabel('Time (ms)');
ylabel('|I + jQ|');
title('Spark Only - I/Q Magnitude');
grid on;

%% Simple smoothing
windowLength = 200;
smoothMag = movmean(mag, windowLength);

figure;
plot(t(1:Nshow)*1000, smoothMag(1:Nshow));
xlabel('Time (ms)');
ylabel('Smoothed Magnitude');
title('Spark Only - Smoothed Envelope');
grid on;

%% Basic measurements
meanLevel = mean(mag);
rmsLevel = rms(mag);
peakLevel = max(mag);

fprintf('\nMean magnitude: %.6f\n', meanLevel);
fprintf('RMS magnitude: %.6f\n', rmsLevel);
fprintf('Peak magnitude: %.6f\n', peakLevel);
fprintf('Peak / RMS ratio: %.2f\n', peakLevel/rmsLevel);