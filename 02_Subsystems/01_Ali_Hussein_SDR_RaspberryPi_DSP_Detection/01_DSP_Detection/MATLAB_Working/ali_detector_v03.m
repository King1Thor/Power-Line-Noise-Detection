clear;
clc;
close all;

%% Load all three Talley test files
sparkData = load('SPARK_ONLY_001.mat');
noiseData = load('WN_ONLY_001.mat');
mixedData = load('SPARK_NOISE_EQUAL_RMS_001.mat');

sparkIQ = sparkData.eventIQ;
noiseIQ = noiseData.eventIQ;
mixedIQ = mixedData.eventIQ;

fs = sparkData.fs;
fc = sparkData.fc;

fprintf('Sample rate: %.0f Hz\n', fs);
fprintf('Center frequency: %.1f MHz\n\n', fc/1e6);

%% Magnitude
sparkMag = abs(sparkIQ);
noiseMag = abs(noiseIQ);
mixedMag = abs(mixedIQ);

%% Measurements
sparkRMS = rms(sparkMag);
sparkPeak = max(sparkMag);
sparkPeakRMS = sparkPeak / sparkRMS;

noiseRMS = rms(noiseMag);
noisePeak = max(noiseMag);
noisePeakRMS = noisePeak / noiseRMS;

mixedRMS = rms(mixedMag);
mixedPeak = max(mixedMag);
mixedPeakRMS = mixedPeak / mixedRMS;

%% Print results
fprintf('========== SPARK ONLY ==========\n');
fprintf('RMS magnitude: %.6f\n', sparkRMS);
fprintf('Peak magnitude: %.6f\n', sparkPeak);
fprintf('Peak / RMS ratio: %.2f\n\n', sparkPeakRMS);

fprintf('========== WHITE NOISE ONLY ==========\n');
fprintf('RMS magnitude: %.6f\n', noiseRMS);
fprintf('Peak magnitude: %.6f\n', noisePeak);
fprintf('Peak / RMS ratio: %.2f\n\n', noisePeakRMS);

fprintf('========== SPARK + NOISE ==========\n');
fprintf('RMS magnitude: %.6f\n', mixedRMS);
fprintf('Peak magnitude: %.6f\n', mixedPeak);
fprintf('Peak / RMS ratio: %.2f\n\n', mixedPeakRMS);

%% Plot first 50 ms
showTime = 0.05;
Nshow = round(showTime * fs);
t = (0:length(mixedIQ)-1) / fs;

windowLength = 200;

sparkSmooth = movmean(sparkMag, windowLength);
noiseSmooth = movmean(noiseMag, windowLength);
mixedSmooth = movmean(mixedMag, windowLength);

figure;
plot(t(1:Nshow)*1000, mixedSmooth(1:Nshow));
xlabel('Time (ms)');
ylabel('Smoothed Magnitude');
title('Spark + Noise - Smoothed Envelope');
grid on;

%% Compare all three
figure;

values = [sparkPeakRMS, noisePeakRMS, mixedPeakRMS];

bar(values);

set(gca, 'XTickLabel', ...
    {'Spark Only', 'White Noise Only', 'Spark + Noise'});

ylabel('Peak / RMS Ratio');
title('Peak / RMS Comparison');
grid on;

%% First simple detection rule
threshold = 8;

fprintf('========== SIMPLE DETECTOR ==========\n');
fprintf('Threshold = %.2f\n', threshold);
fprintf('Mixed Peak/RMS = %.2f\n', mixedPeakRMS);

if mixedPeakRMS > threshold
    fprintf('CANDIDATE SPARK EVENT DETECTED\n');
else
    fprintf('NO EVENT DETECTED\n');
end