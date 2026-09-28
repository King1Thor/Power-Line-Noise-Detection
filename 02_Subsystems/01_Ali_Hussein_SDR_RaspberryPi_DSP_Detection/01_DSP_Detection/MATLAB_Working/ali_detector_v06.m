clear;
clc;
close all;

%% =========================================================
% Ali Detector v06
% Validate the detector using all three known Talley signals
%% =========================================================

fileNames = {
    'WN_ONLY_001.mat'
    'SPARK_ONLY_001.mat'
    'SPARK_NOISE_EQUAL_RMS_001.mat'
};

fileLabels = {
    'White Noise Only'
    'Spark Only'
    'Spark + Noise'
};

% Ground truth
% 0 = no spark expected
% 1 = spark expected
expectedResult = [0 1 1];

numFiles = length(fileNames);

detectedResult = zeros(1,numFiles);
peakRMSresults = zeros(1,numFiles);
eventCounts = zeros(1,numFiles);
repetitionRates = zeros(1,numFiles);

fprintf('=============================================\n');
fprintf('     ALI DETECTOR v06 VALIDATION TEST\n');
fprintf('=============================================\n\n');

%% Process each file
for n = 1:numFiles

    fprintf('\n---------------------------------------------\n');
    fprintf('%s\n', fileLabels{n});
    fprintf('---------------------------------------------\n');

    %% Load file
    data = load(fileNames{n});

    iq = data.eventIQ;
    fs = data.fs;

    %% Magnitude
    mag = abs(iq);

    %% Peak / RMS feature
    rmsLevel = rms(mag);
    peakLevel = max(mag);
    peakRMS = peakLevel / rmsLevel;

    peakRMSresults(n) = peakRMS;

    %% Smooth signal
    windowLength = 200;
    smoothMag = movmean(mag, windowLength);

    %% Adaptive baseline
    baseline = median(smoothMag);
    threshold = baseline * 1.5;

    %% Event detector settings
    minPeakDistance = round(0.006 * fs);
    minProminence = 0.006;

    %% Find events
    [~, peakLocations] = findpeaks( ...
        smoothMag, ...
        'MinPeakHeight', threshold, ...
        'MinPeakProminence', minProminence, ...
        'MinPeakDistance', minPeakDistance);

    eventCount = length(peakLocations);
    eventCounts(n) = eventCount;

    %% Timing analysis
    repetitionRate = 0;
    repeatingPattern = false;

    if eventCount > 1

        peakTimes = peakLocations / fs;

        spacing = diff(peakTimes);

        medianSpacing = median(spacing);

        repetitionRate = 1 / medianSpacing;

        repetitionRates(n) = repetitionRate;

        %% Accept roughly 120 Hz repeating behavior
        if medianSpacing > 0.007 && medianSpacing < 0.010
            repeatingPattern = true;
        end

    end

    %% Final decision
    %
    % Require BOTH:
    % 1. impulsive Peak/RMS behavior
    % 2. repeating timing pattern

    peakRMSThreshold = 8;

    if peakRMS > peakRMSThreshold && repeatingPattern
        detectedResult(n) = 1;
    else
        detectedResult(n) = 0;
    end

    %% Print results
    fprintf('Peak/RMS: %.2f\n', peakRMS);
    fprintf('Events detected: %d\n', eventCount);

    if repetitionRate > 0
        fprintf('Repetition rate: %.2f Hz\n', repetitionRate);
    else
        fprintf('Repetition rate: N/A\n');
    end

    if detectedResult(n) == 1
        fprintf('Detector result: CANDIDATE SPARK\n');
    else
        fprintf('Detector result: NO SPARK\n');
    end

    if expectedResult(n) == detectedResult(n)
        fprintf('Validation: PASS\n');
    else
        fprintf('Validation: FAIL\n');
    end

end

%% Overall validation
correct = sum(expectedResult == detectedResult);
accuracy = 100 * correct / numFiles;

fprintf('\n\n=============================================\n');
fprintf('            FINAL VALIDATION\n');
fprintf('=============================================\n');

fprintf('Correct tests: %d / %d\n', correct, numFiles);
fprintf('Validation accuracy: %.1f %%\n\n', accuracy);

for n = 1:numFiles

    fprintf('%-20s  Expected: %d   Detected: %d\n', ...
        fileLabels{n}, ...
        expectedResult(n), ...
        detectedResult(n));

end

%% Comparison plot
figure;

bar(peakRMSresults);

set(gca, ...
    'XTick', 1:numFiles, ...
    'XTickLabel', fileLabels);

ylabel('Peak / RMS Ratio');
title('Ali Detector v06 - Known Signal Validation');
grid on;

yline(8, '--', 'Peak/RMS Threshold');