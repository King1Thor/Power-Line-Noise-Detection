clear;
clc;
close all;

%% Load Talley's mixed spark + noise test file
data = load('SPARK_NOISE_EQUAL_RMS_001.mat');

iq = data.eventIQ;
fs = data.fs;
fc = data.fc;

fprintf('Sample rate: %.0f Hz\n', fs);
fprintf('Center frequency: %.1f MHz\n\n', fc/1e6);

%% Magnitude
mag = abs(iq);

%% Smooth the magnitude
windowLength = 200;
smoothMag = movmean(mag, windowLength);

%% Estimate baseline and threshold
baseline = median(smoothMag);

% Simple threshold above the background level
threshold = baseline * 1.5;

fprintf('Baseline level: %.6f\n', baseline);
fprintf('Detection threshold: %.6f\n\n', threshold);

%% Find candidate peaks
% Minimum spacing of 2 ms between detected events
minPeakDistance = round(0.002 * fs);

[peakValues, peakLocations] = findpeaks( ...
    smoothMag, ...
    'MinPeakHeight', threshold, ...
    'MinPeakDistance', minPeakDistance);

%% Convert sample locations to time
peakTimes = peakLocations / fs;

%% Print detected events
fprintf('========== DETECTED EVENTS ==========\n');
fprintf('Number of candidate events: %d\n\n', length(peakTimes));

for k = 1:length(peakTimes)
    fprintf('Event %d: %.6f seconds\n', k, peakTimes(k));
end

%% Time difference between events
if length(peakTimes) > 1

    eventSpacing = diff(peakTimes);

    fprintf('\n========== EVENT SPACING ==========\n');

    for k = 1:length(eventSpacing)
        fprintf('Spacing %d: %.6f seconds\n', ...
            k, eventSpacing(k));
    end

    fprintf('\nAverage spacing: %.6f seconds\n', ...
        mean(eventSpacing));

    fprintf('Average spacing: %.3f ms\n', ...
        mean(eventSpacing) * 1000);
end

%% Plot first 100 ms
showTime = 0.1;
Nshow = round(showTime * fs);

t = (0:length(iq)-1) / fs;

figure;

plot(t(1:Nshow)*1000, smoothMag(1:Nshow));
hold on;

%% Plot threshold
yline(threshold, '--', 'Detection Threshold');

%% Only show detected events inside first 100 ms
visibleEvents = peakLocations <= Nshow;

plot( ...
    peakTimes(visibleEvents)*1000, ...
    peakValues(visibleEvents), ...
    'ro', ...
    'MarkerSize', 7, ...
    'LineWidth', 1.5);

xlabel('Time (ms)');
ylabel('Smoothed Magnitude');
title('Candidate Spark Event Detection');
grid on;

legend( ...
    'Smoothed Signal', ...
    'Detection Threshold', ...
    'Detected Events');

hold off;

%% Simple summary
fprintf('\n========== SUMMARY ==========\n');

if isempty(peakTimes)
    fprintf('NO CANDIDATE EVENTS DETECTED\n');
else
    fprintf('CANDIDATE SPARK EVENTS DETECTED\n');
end