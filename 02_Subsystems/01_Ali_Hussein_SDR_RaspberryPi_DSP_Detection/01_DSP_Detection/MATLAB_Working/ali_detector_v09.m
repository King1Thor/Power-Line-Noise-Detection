clear;
clc;
close all;

%% =========================================================
% Ali Detector v09
% 60 Hz cycle-fold / phase-pattern analysis
%
% Subsystem:
% SDR + Raspberry Pi + DSP/Detection
%
% Current stage:
% Improve detector using real saved SDR I/Q data
%
% IMPORTANT:
% This does NOT confirm a power-line spark.
% It looks for RF energy that repeats at similar positions
% within the nominal 60 Hz power cycle.
%% =========================================================

files = {
    'road_event_20260911_182619_107_UTC.mat'
    'road_event_20260911_184400_330_UTC.mat'
    'road_event_20260911_191220_112_UTC.mat'
    'road_event_20260911_210016_757_UTC.mat'
};

labels = {
    'Indoor'
    'Outdoor'
    'Repeater / Reference'
    'Field + GPS'
};

mainsHz = 60;

N = length(files);

foldRangeDB = nan(N,1);
strongestPhaseDeg = nan(N,1);
strongestPhaseMS = nan(N,1);
peakRMS = nan(N,1);

fprintf('=============================================\n');
fprintf('   ALI DETECTOR v09 - 60 Hz PHASE ANALYSIS\n');
fprintf('=============================================\n');

for n = 1:N

    fprintf('\n---------------------------------------------\n');
    fprintf('%s\n', labels{n});
    fprintf('---------------------------------------------\n');

    %% Load
    D = load(files{n});

    iq = double(D.eventIQ(:));
    fs = double(D.fs);

    %% Remove SDR DC offset
    iq = iq - mean(iq);

    %% Low-pass filter
    cutoffHz = min(50e3, 0.45*fs);

    try
        iqFilt = lowpass(iq, cutoffHz, fs);
    catch
        warning('lowpass() failed. Using unfiltered IQ.');
        iqFilt = iq;
    end

    %% Magnitude / power
    mag = abs(iqFilt);
    powerSignal = mag.^2;

    %% Peak/RMS feature for reference
    peakRMS(n) = max(mag) / rms(mag);

    %% =====================================================
    % Fold recording into 60 Hz cycles
    %% =====================================================

    samplesPerCycle = round(fs / mainsHz);

    nCycles = floor(length(powerSignal) / samplesPerCycle);

    samplesUsed = nCycles * samplesPerCycle;

    powerUse = powerSignal(1:samplesUsed);

    cycleMatrix = reshape( ...
        powerUse, ...
        samplesPerCycle, ...
        nCycles);

    %% Average power at each position in the cycle
    avgCyclePower = mean(cycleMatrix, 2);

    avgCycleDB = 10*log10(avgCyclePower + eps);

    %% Fold range
    foldRangeDB(n) = ...
        max(avgCycleDB) - min(avgCycleDB);

    %% Strongest phase location
    [~, idxMax] = max(avgCycleDB);

    strongestPhaseMS(n) = ...
        (idxMax-1) / fs * 1000;

    strongestPhaseDeg(n) = ...
        (idxMax-1) / samplesPerCycle * 360;

    %% Print results
    fprintf('Peak/RMS: %.2f\n', peakRMS(n));
    fprintf('60 Hz fold range: %.2f dB\n', foldRangeDB(n));

    fprintf('Strongest phase: %.2f degrees\n', ...
        strongestPhaseDeg(n));

    fprintf('Strongest position: %.3f ms\n', ...
        strongestPhaseMS(n));

    %% =====================================================
    % Plot average 60 Hz cycle
    %% =====================================================

    cycleTimeMS = ...
        (0:samplesPerCycle-1)' / fs * 1000;

    figure('Name', labels{n});

    plot(cycleTimeMS, avgCycleDB);
    hold on;

    plot( ...
        strongestPhaseMS(n), ...
        avgCycleDB(idxMax), ...
        'ro', ...
        'MarkerSize', 8, ...
        'LineWidth', 1.5);

    xlabel('Position Within 60 Hz Cycle (ms)');
    ylabel('Average RF Power (dB)');
    title(['v09 60 Hz Fold - ' labels{n}]);

    grid on;
    hold off;

end

%% =========================================================
% Results table
%% =========================================================

Recording = string(labels);
File = string(files);

results = table( ...
    Recording, ...
    File, ...
    peakRMS, ...
    foldRangeDB, ...
    strongestPhaseDeg, ...
    strongestPhaseMS);

disp(results);

writetable(results, 'ali_detector_v09_results.csv');

fprintf('\nSaved results to ali_detector_v09_results.csv\n');

%% =========================================================
% Comparison plot
%% =========================================================

figure;

bar(categorical(labels), foldRangeDB);

ylabel('60 Hz Fold Range (dB)');
title('60 Hz Phase-Locked RF Variation');
grid on;

%% =========================================================
% Summary
%% =========================================================

fprintf('\n=============================================\n');
fprintf('                 SUMMARY\n');
fprintf('=============================================\n');

for n = 1:N

    fprintf('%-22s : ', labels{n});

    fprintf('Fold range %.2f dB, strongest phase %.1f deg\n', ...
        foldRangeDB(n), ...
        strongestPhaseDeg(n));

end

fprintf('\n');
fprintf('Interpretation:\n');
fprintf('Larger fold variation means RF energy changes more strongly\n');
fprintf('with position in the nominal 60 Hz cycle.\n');
fprintf('This alone does NOT confirm a power-line spark.\n');