clear;
clc;
close all;

%% =========================================================
% Ali Detector v08
% Compare detector behavior on all four REAL Talley recordings
%
% This is still DSP/Detection development.
% No recording is labeled as a confirmed power-line spark.
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

N = length(files);

eventCount = zeros(N,1);
peakRMS = zeros(N,1);
medianSpacingMS = nan(N,1);
repetitionHz = nan(N,1);
repeating120 = false(N,1);

fprintf('=============================================\n');
fprintf('   ALI DETECTOR v08 - REAL DATA COMPARISON\n');
fprintf('=============================================\n');

for n = 1:N

    fprintf('\n---------------------------------------------\n');
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

    %% Magnitude
    mag = abs(iqFilt);

    %% Peak / RMS
    peakRMS(n) = max(mag) / rms(mag);

    %% Smooth
    smoothingTime = 0.001;

    smoothingSamples = ...
        max(1,round(smoothingTime*fs));

    smoothMag = movmean(mag,smoothingSamples);

    smoothDBFS = ...
        20*log10(smoothMag + eps);

    %% Adaptive threshold
    baseline = median(smoothDBFS);

    madLevel = ...
        median(abs(smoothDBFS-baseline));

    threshold = ...
        baseline + 6*madLevel;

    %% Event detection
    minPeakDistance = ...
        round(0.004*fs);

    minProminenceDB = 3;

    [~,locs] = findpeaks( ...
        smoothDBFS, ...
        'MinPeakHeight',threshold, ...
        'MinPeakProminence',minProminenceDB, ...
        'MinPeakDistance',minPeakDistance);

    eventCount(n) = length(locs);

    %% Timing analysis
    if length(locs) > 1

        times = locs/fs;

        spacing = diff(times);

        medianSpacing = median(spacing);

        medianSpacingMS(n) = ...
            medianSpacing*1000;

        repetitionHz(n) = ...
            1/medianSpacing;

        %% Check approximately 120 Hz
        if medianSpacing > 0.007 && ...
           medianSpacing < 0.010

            repeating120(n) = true;

        end

    end

    %% Print
    fprintf('Peak/RMS: %.2f\n',peakRMS(n));
    fprintf('Candidate events: %d\n',eventCount(n));

    if ~isnan(medianSpacingMS(n))

        fprintf('Median spacing: %.3f ms\n', ...
            medianSpacingMS(n));

        fprintf('Estimated repetition: %.2f Hz\n', ...
            repetitionHz(n));

    else
        fprintf('Median spacing: N/A\n');
        fprintf('Estimated repetition: N/A\n');
    end

    if repeating120(n)
        fprintf('Timing result: 120 Hz-LIKE PATTERN\n');
    elseif eventCount(n) > 0
        fprintf('Timing result: IMPULSIVE, NO CLEAR 120 Hz PATTERN\n');
    else
        fprintf('Timing result: NO STRONG CANDIDATE EVENTS\n');
    end

end

%% =========================================================
% Results table
%% =========================================================

File = string(files);
Recording = string(labels);

results = table( ...
    Recording, ...
    File, ...
    peakRMS, ...
    eventCount, ...
    medianSpacingMS, ...
    repetitionHz, ...
    repeating120);

disp(results);

writetable(results,'ali_detector_v08_results.csv');

fprintf('\nSaved results to ali_detector_v08_results.csv\n');

%% =========================================================
% Comparison plots
%% =========================================================

figure;

bar(categorical(labels),peakRMS);

ylabel('Peak / RMS Ratio');
title('Real Recording Impulsiveness Comparison');
grid on;


figure;

bar(categorical(labels),eventCount);

ylabel('Candidate Event Count');
title('Candidate Transient Events by Recording');
grid on;


figure;

bar(categorical(labels),repetitionHz);

ylabel('Estimated Repetition Rate (Hz)');
title('Real Recording Timing Comparison');

yline(60,'--','60 Hz');
yline(120,'--','120 Hz');

grid on;

%% =========================================================
% Final summary
%% =========================================================

fprintf('\n=============================================\n');
fprintf('                SUMMARY\n');
fprintf('=============================================\n');

for n = 1:N

    fprintf('%-22s : ',labels{n});

    if repeating120(n)

        fprintf('CANDIDATE 120 Hz-LIKE IMPULSIVE PATTERN\n');

    elseif eventCount(n) > 0

        fprintf('IMPULSIVE ACTIVITY, NO CLEAR 120 Hz PATTERN\n');

    else

        fprintf('NO STRONG CANDIDATE ACTIVITY\n');

    end

end

fprintf('\n');
fprintf('These classifications do NOT confirm a power-line spark.\n');