clear;
clc;
close all;

%% Load Talley's mixed spark + noise file
data = load('SPARK_NOISE_EQUAL_RMS_001.mat');

iq = data.eventIQ;
fs = data.fs;
fc = data.fc;

fprintf('Sample rate: %.0f Hz\n', fs);
fprintf('Center frequency: %.1f MHz\n\n', fc/1e6);

%% Magnitude
mag = abs(iq);

%% Smooth the signal
windowLength = 200;
smoothMag = movmean(mag, windowLength);

%% Estimate background level
baseline = median(smoothMag);

%% Detection settings
threshold = baseline * 1.5;

% Main fix from v04:
% require events to be at least 6 ms apart
minPeakDistance = round(0.006 * fs);

% Require peaks to stand out from local background
minProminence = 0.006;

fprintf('Baseline: %.6f\n', baseline);
fprintf('Threshold: %.6f\n', threshold);
fprintf('Minimum event spacing: 6 ms\n');
fprintf('Minimum prominence: %.6f\n\n', minProminence);

%% Detect candidate events
[peakValues, peakLocations] = findpeaks( ...
    smoothMag, ...
    'MinPeakHeight', threshold, ...
    'MinPeakProminence', minProminence, ...
    'MinPeakDistance', minPeakDistance);

%% Convert sample locations to time
peakTimes = peakLocations / fs;

%% Print events
fprintf('========== DETECTED EVENTS ==========\n');
fprintf('Number of candidate events: %d\n\n', length(peakTimes));

for k = 1:length(peakTimes)
    fprintf('Event %d: %.6f s\n', k, peakTimes(k));
end

%% Event spacing
if length(peakTimes) > 1

    spacing = diff(peakTimes);

    avgSpacing = mean(spacing);
    medianSpacing = median(spacing);

    fprintf('\n========== EVENT SPACING ==========\n');
    fprintf('Average spacing: %.3f ms\n', avgSpacing * 1000);
    fprintf('Median spacing: %.3f ms\n', medianSpacing * 1000);

    %% Estimate repetition rate
    repetitionRate = 1 / medianSpacing;

    fprintf('Estimated repetition rate: %.2f Hz\n', repetitionRate);

    %% Compare with expected 120 Hz-like behavior
    expectedSpacing = 1 / 120;

    spacingError = abs(medianSpacing - expectedSpacing);

    fprintf('Expected 120 Hz spacing: %.3f ms\n', ...
        expectedSpacing * 1000);

    fprintf('Spacing error: %.3f ms\n', ...
        spacingError * 1000);

end

%% Plot first 100 ms
showTime = 0.1;
Nshow = round(showTime * fs);

t = (0:length(iq)-1) / fs;

figure;

plot(t(1:Nshow)*1000, smoothMag(1:Nshow));
hold on;

yline(threshold, '--', 'Detection Threshold');

visibleEvents = peakLocations <= Nshow;

plot( ...
    peakTimes(visibleEvents)*1000, ...
    peakValues(visibleEvents), ...
    'ro', ...
    'MarkerSize', 7, ...
    'LineWidth', 1.5);

xlabel('Time (ms)');
ylabel('Smoothed Magnitude');
title('v05 Cleaned Candidate Spark Detection');
grid on;

legend( ...
    'Smoothed Signal', ...
    'Detection Threshold', ...
    'Detected Events');

hold off;

%% Final detector summary
fprintf('\n========== DETECTOR SUMMARY ==========\n');

if isempty(peakTimes)

    fprintf('NO CANDIDATE SPARK EVENTS DETECTED\n');

else

    fprintf('CANDIDATE SPARK EVENTS DETECTED\n');

    if length(peakTimes) > 1

        if medianSpacing > 0.007 && medianSpacing < 0.010
            fprintf('REPEATING EVENT PATTERN DETECTED\n');
        else
            fprintf('EVENTS DETECTED, BUT TIMING PATTERN IS NOT CONSISTENT\n');
        end

    end

end