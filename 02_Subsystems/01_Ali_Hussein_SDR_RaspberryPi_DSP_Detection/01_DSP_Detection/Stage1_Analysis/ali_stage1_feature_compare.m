%% Ali Subsystem 3 - Stage 1 Feature Comparison
% Power Line Noise Detection, Analysis, and Location #2
%
% Purpose:
%   Compare all four Dr. Talley starter recordings using the same baseline
%   processing and feature calculations.
%
% IMPORTANT:
%   This script does NOT label any recording as a confirmed power-line spark.
%   It only creates objective measurements for later detector development.
%
% Put this file in the SAME folder as the four road_event_*.mat recordings.
% Then run:
%   ali_stage1_feature_compare

clear;
clc;
close all;

files = dir('road_event_*.mat');
if isempty(files)
    error(['No road_event_*.mat files were found. Put this script in the ', ...
           'same folder as the four Dr. Talley MAT recordings.']);
end

[~, order] = sort({files.name});
files = files(order);
nFiles = numel(files);

File = strings(nFiles,1);
CenterFreq_MHz = nan(nFiles,1);
SampleRate_kSps = nan(nFiles,1);
Duration_s = nan(nFiles,1);
Gain_dB = nan(nFiles,1);
LostTotal = nan(nFiles,1);
Median_dBFS = nan(nFiles,1);
RMS_dBFS = nan(nFiles,1);
P95_dBFS = nan(nFiles,1);
P99_dBFS = nan(nFiles,1);
Peak_dBFS = nan(nFiles,1);
CrestFactor_dB = nan(nFiles,1);
FoldRange_dB = nan(nFiles,1);
StrongestPhase_deg = nan(nFiles,1);
StrongestPhase_ms = nan(nFiles,1);
SpectralPeakOverMedian_dB = nan(nFiles,1);
SpectralFlatness = nan(nFiles,1);
CandidateTransientCount = nan(nFiles,1);

fprintf('\nALI SUBSYSTEM 3 - STAGE 1 FEATURE COMPARISON\n');
fprintf('------------------------------------------------------------\n');
fprintf('These are baseline measurements, NOT confirmed spark labels.\n\n');

for k = 1:nFiles
    filename = files(k).name;
    S = load(filename);

    if ~isfield(S,'eventIQ') || ~isfield(S,'fs')
        warning('%s is missing eventIQ or fs. Skipping.', filename);
        continue;
    end

    x = double(S.eventIQ(:));
    fs = double(S.fs);
    if isfield(S,'mainsFrequency')
        mainsHz = double(S.mainsFrequency);
    else
        mainsHz = 60;
    end

    File(k) = string(filename);
    CenterFreq_MHz(k) = getScalar(S,'fc',NaN)/1e6;
    SampleRate_kSps(k) = fs/1e3;
    Duration_s(k) = (numel(x)-1)/fs;
    Gain_dB(k) = getScalar(S,'gainDB',NaN);
    LostTotal(k) = getScalar(S,'lostTotal',NaN);

    % 1) Baseline preprocessing
    x = x - mean(x);
    cutoffHz = min(50e3, 0.45*fs);
    try
        xFilt = lowpass(x, cutoffHz, fs);
    catch
        warning('lowpass() failed for %s. Using unfiltered IQ.', filename);
        xFilt = x;
    end

    env = abs(xFilt);
    level_dBFS = 20*log10(env + eps);

    % 2) Time-domain features
    Median_dBFS(k) = median(level_dBFS);
    RMS_dBFS(k) = 20*log10(sqrt(mean(abs(xFilt).^2)) + eps);
    P95_dBFS(k) = simplePercentile(level_dBFS,95);
    P99_dBFS(k) = simplePercentile(level_dBFS,99);
    Peak_dBFS(k) = max(level_dBFS);
    rmsEnv = sqrt(mean(env.^2));
    CrestFactor_dB(k) = 20*log10((max(env)+eps)/(rmsEnv+eps));

    % 3) Nominal 60 Hz cycle folding
    samplesPerCycle = round(fs/mainsHz);
    nCycles = floor(numel(xFilt)/samplesPerCycle);
    if nCycles >= 2
        xUse = xFilt(1:nCycles*samplesPerCycle);
        powerMatrix = reshape(abs(xUse).^2, samplesPerCycle, nCycles);
        avgCyclePower = mean(powerMatrix,2);
        avgCycle_dB = 10*log10(avgCyclePower + eps);
        FoldRange_dB(k) = max(avgCycle_dB) - min(avgCycle_dB);
        [~, idxMax] = max(avgCycle_dB);
        StrongestPhase_ms(k) = (idxMax-1)/fs*1000;
        StrongestPhase_deg(k) = mod((idxMax-1)/samplesPerCycle*360,360);
    end

    % 4) Frequency-domain features
    nfft = min(8192, max(1024, 2^nextpow2(min(numel(xFilt),8192))));
    windowLength = min(4096, numel(xFilt));
    if windowLength >= 256
        overlap = floor(0.5*windowLength);
        [Pxx,~] = pwelch(xFilt, hann(windowLength,'periodic'), overlap, nfft, fs, 'centered');
        Pxx = real(Pxx(:));
        Pxx(Pxx <= 0) = eps;
        Pxx_dB = 10*log10(Pxx);
        SpectralPeakOverMedian_dB(k) = max(Pxx_dB) - median(Pxx_dB);
        SpectralFlatness(k) = exp(mean(log(Pxx))) / mean(Pxx);
    end

    % 5) Exploratory transient count
    % Adaptive only. This is NOT the final detector.
    medLevel = median(level_dBFS);
    madLevel = median(abs(level_dBFS - medLevel));
    threshold = medLevel + 6*madLevel;
    above = level_dBFS > threshold;
    starts = find(diff([false; above]) == 1);

    if isempty(starts)
        CandidateTransientCount(k) = 0;
    else
        minGap = round(0.002*fs); % merge crossings within 2 ms
        CandidateTransientCount(k) = 1 + sum(diff(starts) > minGap);
    end

    fprintf('%d/%d  %s\n', k, nFiles, filename);
    fprintf('  Median level:            %8.2f dBFS\n', Median_dBFS(k));
    fprintf('  Peak level:              %8.2f dBFS\n', Peak_dBFS(k));
    fprintf('  Crest factor:            %8.2f dB\n', CrestFactor_dB(k));
    fprintf('  60 Hz fold range:        %8.2f dB\n', FoldRange_dB(k));
    fprintf('  Strongest cycle phase:   %8.2f deg (%6.3f ms)\n', StrongestPhase_deg(k), StrongestPhase_ms(k));
    fprintf('  Spectral peak/median:    %8.2f dB\n', SpectralPeakOverMedian_dB(k));
    fprintf('  Spectral flatness:       %8.4f\n', SpectralFlatness(k));
    fprintf('  Candidate transients:    %8d\n\n', CandidateTransientCount(k));
end

T = table(File, CenterFreq_MHz, SampleRate_kSps, Duration_s, Gain_dB, LostTotal, ...
          Median_dBFS, RMS_dBFS, P95_dBFS, P99_dBFS, Peak_dBFS, CrestFactor_dB, ...
          FoldRange_dB, StrongestPhase_deg, StrongestPhase_ms, ...
          SpectralPeakOverMedian_dB, SpectralFlatness, CandidateTransientCount);

disp(T);
outFile = 'ali_stage1_feature_table.csv';
writetable(T,outFile);
fprintf('Saved feature table to: %s\n', outFile);

figure('Name','Ali Stage 1 - Recording Level Comparison');
bar(categorical(shortNames(File)), Median_dBFS);
ylabel('Median received level (dBFS)');
title('Median Received Level by Recording');
grid on;

figure('Name','Ali Stage 1 - 60 Hz Fold Comparison');
bar(categorical(shortNames(File)), FoldRange_dB);
ylabel('Max - min average cycle level (dB)');
title('60 Hz Fold Variation by Recording');
grid on;

figure('Name','Ali Stage 1 - Spectral Concentration Comparison');
bar(categorical(shortNames(File)), SpectralPeakOverMedian_dB);
ylabel('Peak PSD - median PSD (dB)');
title('Spectral Concentration by Recording');
grid on;

fprintf('\nStage 1 complete.\n');
fprintf('Next step: interpret the table before choosing detector features.\n');

function value = getScalar(S,fieldName,defaultValue)
    if isfield(S,fieldName)
        temp = S.(fieldName);
        if isnumeric(temp) && isscalar(temp)
            value = double(temp);
        else
            value = defaultValue;
        end
    else
        value = defaultValue;
    end
end

function p = simplePercentile(x,q)
    x = sort(x(:));
    n = numel(x);
    if n == 0
        p = NaN;
        return;
    end
    pos = 1 + (n-1)*(q/100);
    lo = floor(pos);
    hi = ceil(pos);
    if lo == hi
        p = x(lo);
    else
        p = x(lo) + (pos-lo)*(x(hi)-x(lo));
    end
end

function names = shortNames(fileNames)
    names = strings(size(fileNames));
    for i = 1:numel(fileNames)
        s = char(fileNames(i));
        token = regexp(s,'road_event_\d+_(\d+)_UTC','tokens','once');
        if isempty(token)
            names(i) = string(s);
        else
            names(i) = string(token{1});
        end
    end
end
