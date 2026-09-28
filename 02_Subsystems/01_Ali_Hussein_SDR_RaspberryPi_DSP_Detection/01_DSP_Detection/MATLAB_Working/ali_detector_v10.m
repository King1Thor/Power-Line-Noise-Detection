clear;
clc;
close all;

%% =========================================================
% Ali Detector v10
% Combined impulsiveness + 60 Hz phase detector
%
% Current subsystem stage:
% DSP / Detection
%
% IMPORTANT:
% This is a provisional detector.
% It does NOT confirm a power-line spark.
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

peakRMS = nan(N,1);
foldRangeDB = nan(N,1);
strongestPhaseDeg = nan(N,1);
classification = strings(N,1);

%% Provisional detector thresholds
peakRMSThreshold = 8;
foldThresholdDB = 2;

fprintf('=============================================\n');
fprintf('      ALI DETECTOR v10 - COMBINED DSP\n');
fprintf('=============================================\n\n');

fprintf('Provisional Peak/RMS threshold: %.2f\n', ...
    peakRMSThreshold);

fprintf('Provisional fold threshold: %.2f dB\n\n', ...
    foldThresholdDB);

for n = 1:N

    fprintf('---------------------------------------------\n');
    fprintf('%s\n', labels{n});
    fprintf('---------------------------------------------\n');

    %% Load
    D = load(files{n});

    iq = double(D.eventIQ(:));
    fs = double(D.fs);

    %% Remove DC offset
    iq = iq - mean(iq);

    %% Filter
    cutoffHz = min(50e3,0.45*fs);

    try
        iqFilt = lowpass(iq,cutoffHz,fs);
    catch
        iqFilt = iq;
    end

    %% =====================================================
    % Feature 1: impulsiveness
    %% =====================================================

    mag = abs(iqFilt);

    peakRMS(n) = ...
        max(mag) / rms(mag);

    %% =====================================================
    % Feature 2: 60 Hz cycle variation
    %% =====================================================

    samplesPerCycle = ...
        round(fs/mainsHz);

    nCycles = ...
        floor(length(iqFilt)/samplesPerCycle);

    samplesUsed = ...
        nCycles*samplesPerCycle;

    powerSignal = ...
        abs(iqFilt(1:samplesUsed)).^2;

    cycleMatrix = reshape( ...
        powerSignal, ...
        samplesPerCycle, ...
        nCycles);

    avgCyclePower = ...
        mean(cycleMatrix,2);

    avgCycleDB = ...
        10*log10(avgCyclePower + eps);

    foldRangeDB(n) = ...
        max(avgCycleDB) - min(avgCycleDB);

    [~,idxMax] = max(avgCycleDB);

    strongestPhaseDeg(n) = ...
        (idxMax-1)/samplesPerCycle*360;

    %% =====================================================
    % Combined provisional classification
    %% =====================================================

    impulsive = ...
        peakRMS(n) > peakRMSThreshold;

    phaseDependent = ...
        foldRangeDB(n) > foldThresholdDB;

    if impulsive && phaseDependent

        classification(n) = ...
            "CANDIDATE PHASE-DEPENDENT IMPULSIVE RF ACTIVITY";

    elseif impulsive

        classification(n) = ...
            "IMPULSIVE RF ACTIVITY ONLY";

    elseif phaseDependent

        classification(n) = ...
            "60 Hz PHASE VARIATION WITHOUT STRONG IMPULSIVENESS";

    else

        classification(n) = ...
            "NO STRONG COMBINED CANDIDATE";

    end

    %% Print
    fprintf('Peak/RMS: %.2f\n',peakRMS(n));
    fprintf('60 Hz fold range: %.2f dB\n',foldRangeDB(n));

    fprintf('Strongest phase: %.1f deg\n', ...
        strongestPhaseDeg(n));

    fprintf('Result: %s\n\n',classification(n));

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
    classification);

disp(results);

writetable(results,'ali_detector_v10_results.csv');

fprintf('Saved results to ali_detector_v10_results.csv\n');

%% =========================================================
% Feature-space plot
%% =========================================================

figure;

scatter(peakRMS,foldRangeDB,100,'filled');

hold on;

xline(peakRMSThreshold,'--','Peak/RMS Threshold');
yline(foldThresholdDB,'--','Fold Threshold');

for n = 1:N

    text( ...
        peakRMS(n)+0.5, ...
        foldRangeDB(n), ...
        labels{n});

end

xlabel('Peak / RMS Ratio');
ylabel('60 Hz Fold Range (dB)');
title('Ali Detector v10 - Combined Feature Space');
grid on;

hold off;

%% =========================================================
% Final note
%% =========================================================

fprintf('\n=============================================\n');
fprintf('NOTE\n');
fprintf('=============================================\n');

fprintf(['This detector identifies candidate RF behavior only.\n' ...
         'It does NOT establish that the source is a\n' ...
         'power-line spark. Controlled validation is still required.\n']);