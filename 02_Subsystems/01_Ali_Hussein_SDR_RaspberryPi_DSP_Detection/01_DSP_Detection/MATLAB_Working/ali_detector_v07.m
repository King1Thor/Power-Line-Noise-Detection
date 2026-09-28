clear;
clc;
close all;

%% =========================================================
% Ali Detector v07
% Real field recording validation
%
% Subsystem:
% SDR + Raspberry Pi + DSP/Detection
%
% Current stage:
% DSP/Detection using saved SDR I/Q data
%
% IMPORTANT:
% This script does NOT confirm power-line sparking.
% It only looks for candidate impulsive RF activity.
%% =========================================================

%% Load Talley's real field recording
data = load('road_event_20260911_210016_757_UTC.mat');

iq = double(data.eventIQ(:));
fs = double(data.fs);
fc = double(data.fc);

fprintf('=============================================\n');
fprintf('      ALI DETECTOR v07 - REAL FIELD DATA\n');
fprintf('=============================================\n\n');

fprintf('Sample rate: %.0f Hz\n', fs);
fprintf('Center frequency: %.6f MHz\n', fc/1e6);
fprintf('Samples: %d\n', length(iq));
fprintf('Duration: %.3f seconds\n\n', length(iq)/fs);

%% Remove SDR DC offset
iq = iq - mean(iq);

%% Low-pass / channel filter
cutoffHz = min(50e3, 0.45*fs);

try
    iqFilt = lowpass(iq, cutoffHz, fs);
catch
    warning('lowpass() failed. Using unfiltered IQ.');
    iqFilt = iq;
end

%% Magnitude / envelope
mag = abs(iqFilt);

%% Convert to dBFS
levelDBFS = 20*log10(mag + eps);

%% Smooth the received level
smoothingTime = 0.001;   % 1 ms

smoothingSamples = max(1, round(smoothingTime * fs));

smoothMag = movmean(mag, smoothingSamples);

smoothDBFS = 20*log10(smoothMag + eps);

%% =========================================================
% Baseline estimation
%% =========================================================

baseline = median(smoothDBFS);

madLevel = median(abs(smoothDBFS - baseline));

threshold = baseline + 6*madLevel;

fprintf('========== BASELINE ==========\n');
fprintf('Median baseline: %.2f dBFS\n', baseline);
fprintf('MAD: %.2f dB\n', madLevel);
fprintf('Detection threshold: %.2f dBFS\n\n', threshold);

%% =========================================================
% Detect candidate transient events
%% =========================================================

% Require candidate events to be separated by at least 4 ms
minPeakDistance = round(0.004 * fs);

% Require local prominence
minProminenceDB = 3;

[peakValues, peakLocations] = findpeaks( ...
    smoothDBFS, ...
    'MinPeakHeight', threshold, ...
    'MinPeakProminence', minProminenceDB, ...
    'MinPeakDistance', minPeakDistance);

peakTimes = peakLocations / fs;

eventCount = length(peakTimes);

fprintf('========== CANDIDATE EVENTS ==========\n');
fprintf('Candidate transient count: %d\n\n', eventCount);

%% Print first 20 event times only
maxPrint = min(eventCount,20);

for k = 1:maxPrint
    fprintf('Event %d: %.6f s\n', k, peakTimes(k));
end

if eventCount > maxPrint
    fprintf('... %d additional events not printed\n', ...
        eventCount-maxPrint);
end

%% =========================================================
% Event spacing analysis
%% =========================================================

medianSpacing = NaN;
meanSpacing = NaN;
repetitionRate = NaN;

if eventCount > 1

    spacing = diff(peakTimes);

    medianSpacing = median(spacing);
    meanSpacing = mean(spacing);

    repetitionRate = 1 / medianSpacing;

    fprintf('\n========== EVENT SPACING ==========\n');
    fprintf('Mean spacing: %.3f ms\n', meanSpacing*1000);
    fprintf('Median spacing: %.3f ms\n', medianSpacing*1000);
    fprintf('Estimated repetition rate: %.2f Hz\n', repetitionRate);

end

%% =========================================================
% Compare timing against 60 Hz and 120 Hz
%% =========================================================

expected60 = 1/60;
expected120 = 1/120;

if eventCount > 1

    error60 = abs(medianSpacing - expected60);
    error120 = abs(medianSpacing - expected120);

    fprintf('\n========== TIMING COMPARISON ==========\n');

    fprintf('60 Hz expected spacing: %.3f ms\n', ...
        expected60*1000);

    fprintf('120 Hz expected spacing: %.3f ms\n', ...
        expected120*1000);

    fprintf('Error from 60 Hz: %.3f ms\n', ...
        error60*1000);

    fprintf('Error from 120 Hz: %.3f ms\n', ...
        error120*1000);

end

%% =========================================================
% Peak/RMS feature
%% =========================================================

rmsLevel = rms(mag);
peakLevel = max(mag);

peakRMS = peakLevel / rmsLevel;

fprintf('\n========== SIGNAL FEATURE ==========\n');
fprintf('Peak/RMS ratio: %.2f\n', peakRMS);

%% =========================================================
% Simple classification
%% =========================================================

repeatingPattern = false;

if eventCount > 5

    if medianSpacing > 0.007 && medianSpacing < 0.010
        repeatingPattern = true;
    end

end

fprintf('\n========== DETECTOR RESULT ==========\n');

if repeatingPattern

    fprintf('CANDIDATE REPEATING IMPULSIVE RF ACTIVITY\n');

else

    if eventCount > 0
        fprintf('IMPULSIVE RF ACTIVITY DETECTED\n');
        fprintf('NO CLEAR 120 Hz-LIKE REPEATING PATTERN\n');
    else
        fprintf('NO STRONG CANDIDATE TRANSIENT ACTIVITY\n');
    end

end

fprintf('\n');
fprintf('NOTE: This result does NOT confirm a power-line spark.\n');
fprintf('Controlled testing is required for source attribution.\n');

%% =========================================================
% Plot first 1 second
%% =========================================================

showTime = min(1, length(iq)/fs);

Nshow = round(showTime * fs);

t = (0:length(iq)-1)' / fs;

figure;

plot(t(1:Nshow), smoothDBFS(1:Nshow));
hold on;

yline(threshold, '--', 'Adaptive Threshold');

visibleEvents = peakLocations <= Nshow;

plot( ...
    peakTimes(visibleEvents), ...
    peakValues(visibleEvents), ...
    'ro', ...
    'MarkerSize', 7, ...
    'LineWidth', 1.5);

xlabel('Time (s)');
ylabel('Smoothed Level (dBFS)');
title('v07 Real Field Candidate Event Detection');
grid on;

legend( ...
    'Smoothed Received Level', ...
    'Adaptive Threshold', ...
    'Candidate Events');

hold off;

%% =========================================================
% 60 Hz folded average
%% =========================================================

mainsHz = 60;

samplesPerCycle = round(fs/mainsHz);

nCycles = floor(length(iqFilt)/samplesPerCycle);

if nCycles >= 2

    xUse = iqFilt(1:nCycles*samplesPerCycle);

    cyclePower = reshape( ...
        abs(xUse).^2, ...
        samplesPerCycle, ...
        nCycles);

    averageCycle = mean(cyclePower,2);

    averageCycleDB = 10*log10(averageCycle + eps);

    cycleTimeMS = ...
        (0:samplesPerCycle-1)' / fs * 1000;

    figure;

    plot(cycleTimeMS, averageCycleDB);

    xlabel('Position Within 60 Hz Cycle (ms)');
    ylabel('Average Power (dB)');
    title('v07 Average 60 Hz Fold - Real Field Recording');
    grid on;

end