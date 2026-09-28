clear;
clc;
close all;

%% Load Talley's test files
sparkData = load('SPARK_ONLY_001.mat');
noiseData = load('WN_ONLY_001.mat');

sparkIQ = sparkData.eventIQ;
noiseIQ = noiseData.eventIQ;

fs = sparkData.fs;
fc = sparkData.fc;

%% Basic info
fprintf('Sample rate: %.0f Hz\n', fs);
fprintf('Center frequency: %.1f MHz\n\n', fc/1e6);

%% Magnitude
sparkMag = abs(sparkIQ);
noiseMag = abs(noiseIQ);

%% Smooth both signals
windowLength = 200;

sparkSmooth = movmean(sparkMag, windowLength);
noiseSmooth = movmean(noiseMag, windowLength);

%% Measurements - Spark
sparkMean = mean(sparkMag);
sparkRMS = rms(sparkMag);
sparkPeak = max(sparkMag);
sparkPeakRMS = sparkPeak / sparkRMS;

%% Measurements - Noise
noiseMean = mean(noiseMag);
noiseRMS = rms(noiseMag);
noisePeak = max(noiseMag);
noisePeakRMS = noisePeak / noiseRMS;

%% Print results
fprintf('========== SPARK ONLY ==========\n');
fprintf('Mean magnitude: %.6f\n', sparkMean);
fprintf('RMS magnitude: %.6f\n', sparkRMS);
fprintf('Peak magnitude: %.6f\n', sparkPeak);
fprintf('Peak / RMS ratio: %.2f\n\n', sparkPeakRMS);

fprintf('========== WHITE NOISE ONLY ==========\n');
fprintf('Mean magnitude: %.6f\n', noiseMean);
fprintf('RMS magnitude: %.6f\n', noiseRMS);
fprintf('Peak magnitude: %.6f\n', noisePeak);
fprintf('Peak / RMS ratio: %.2f\n\n', noisePeakRMS);

%% Show first 50 ms
showTime = 0.05;
Nshow = round(showTime * fs);

t = (0:length(sparkIQ)-1) / fs;

%% Plot Spark
figure;
plot(t(1:Nshow)*1000, sparkSmooth(1:Nshow));
xlabel('Time (ms)');
ylabel('Smoothed Magnitude');
title('Spark Only - Smoothed Envelope');
grid on;

%% Plot White Noise
figure;
plot(t(1:Nshow)*1000, noiseSmooth(1:Nshow));
xlabel('Time (ms)');
ylabel('Smoothed Magnitude');
title('White Noise Only - Smoothed Envelope');
grid on;

%% Comparison bar chart
figure;

values = [sparkPeakRMS, noisePeakRMS];

bar(values);

set(gca, 'XTickLabel', {'Spark Only', 'White Noise Only'});

ylabel('Peak / RMS Ratio');
title('Peak / RMS Comparison');
grid on;

%% Simple separation check
fprintf('========== COMPARISON ==========\n');

if sparkPeakRMS > noisePeakRMS
    fprintf('Spark Peak/RMS is higher than white noise.\n');
    fprintf('Difference: %.2f\n', sparkPeakRMS - noisePeakRMS);
else
    fprintf('Peak/RMS does NOT separate the signals well.\n');
end