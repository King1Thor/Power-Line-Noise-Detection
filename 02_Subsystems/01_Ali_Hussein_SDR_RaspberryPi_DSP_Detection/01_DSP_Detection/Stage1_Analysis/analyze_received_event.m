%% ANALYZE_RECEIVED_EVENT
% Analyze a saved complex-IQ recording from road_noise_monitor_2m.
%
% Produces:
%   1. Received level versus time
%   2. RF spectrum
%   3. Average waveform folded into one 60 Hz cycle
%   4. Rolling 60 Hz-cycle waterfall
%   5. Demodulated FM audio spectrum from 0 to 500 Hz
%   6. FM audio spectrogram from 0 to 300 Hz

clearvars
close all
clc

%% Select a recording
[fileName,filePath] = uigetfile( ...
    "*.mat", ...
    "Select a recorded SDR event");

if isequal(fileName,0)
    disp("No file selected.")
    return
end

fullFileName = fullfile(filePath,fileName);
D = load(fullFileName);

%% Verify required variables
requiredVariables = ["eventIQ","fs","fc"];

for k = 1:numel(requiredVariables)
    if ~isfield(D,requiredVariables(k))
        error("The selected file does not contain %s.", ...
            requiredVariables(k))
    end
end

%% Read the recording
iq = double(D.eventIQ(:));
fs = double(D.fs);
fc = double(D.fc);

% Remove constant complex DC offset from the RTL-SDR
iq = iq - mean(iq);

numberSamples = numel(iq);
durationSeconds = numberSamples/fs;
timeSeconds = (0:numberSamples-1)'/fs;

%% Overall signal statistics
magnitude = abs(iq);
magnitudeDBFS = 20*log10(magnitude + eps);

rmsDBFS = 20*log10(sqrt(mean(magnitude.^2)) + eps);
medianDBFS = median(magnitudeDBFS);
p95DBFS = prctile(magnitudeDBFS,95);
peakDBFS = max(magnitudeDBFS);

fprintf("\n")
fprintf("File:              %s\n",fileName)
fprintf("Center frequency:  %.6f MHz\n",fc/1e6)
fprintf("Sample rate:       %.0f samples/second\n",fs)
fprintf("Duration:          %.3f seconds\n",durationSeconds)
fprintf("RMS level:         %.2f dBFS\n",rmsDBFS)
fprintf("Median level:      %.2f dBFS\n",medianDBFS)
fprintf("95th percentile:   %.2f dBFS\n",p95DBFS)
fprintf("Peak level:        %.2f dBFS\n",peakDBFS)

if isfield(D,"gainDB")
    fprintf("Receiver gain:     %.1f dB\n",D.gainDB)
end

if isfield(D,"lostTotal")
    fprintf("Lost samples:      %.0f\n",D.lostTotal)
end

%% Smoothed received level versus time
smoothingTimeSeconds = 0.005;
smoothingSamples = max(1,round(smoothingTimeSeconds*fs));

smoothedPower = movmean(magnitude.^2,smoothingSamples);
smoothedLevelDBFS = 10*log10(smoothedPower + eps);

%% RF spectrum
rfFFTLength = 8192;
rfWindow = hann(rfFFTLength);
rfOverlap = rfFFTLength/2;

[rfPSD,rfFrequencyOffset] = pwelch( ...
    iq, ...
    rfWindow, ...
    rfOverlap, ...
    rfFFTLength, ...
    fs, ...
    "centered");

rfFrequencyMHz = (fc + rfFrequencyOffset)/1e6;
rfPSDDB = 10*log10(rfPSD + eps);

%% Fold the recording into nominal 60 Hz cycles
mainsFrequency = 60;
samplesPerCycle = round(fs/mainsFrequency);
numberCycles = floor(numberSamples/samplesPerCycle);

samplesUsed = numberCycles*samplesPerCycle;

cyclePower = reshape( ...
    magnitude(1:samplesUsed).^2, ...
    samplesPerCycle, ...
    numberCycles);

averageCycleDBFS = 10*log10(mean(cyclePower,2) + eps);
cycleWaterfallDBFS = 10*log10(cyclePower.' + eps);

cyclePositionMS = ...
    (0:samplesPerCycle-1)'/fs*1000;

cycleStartTimeSeconds = ...
    (0:numberCycles-1)'/mainsFrequency;

waterfallColorLimits = ...
    prctile(cycleWaterfallDBFS(:),[5 99]);

%% FM demodulation
% The phase difference between successive IQ samples provides an
% unscaled FM discriminator output.
fmDemodulated = angle(iq(2:end).*conj(iq(1:end-1)));
fmDemodulated = fmDemodulated - mean(fmDemodulated);

% Reduce the demodulated sample rate to approximately 12 kHz.
targetAudioSampleRate = 12000;
decimationFactor = max(1,round(fs/targetAudioSampleRate));

if decimationFactor > 1
    fmAudio = decimate(fmDemodulated,decimationFactor);
else
    fmAudio = fmDemodulated;
end

audioSampleRate = fs/decimationFactor;
audioTimeSeconds = (0:numel(fmAudio)-1)'/audioSampleRate;

%% Demodulated FM audio spectrum
audioFFTLength = 32768;

audioWindowLength = min( ...
    round(2*audioSampleRate), ...
    numel(fmAudio));

audioWindow = hann(audioWindowLength);
audioOverlap = floor(0.75*audioWindowLength);

[audioPSD,audioFrequency] = pwelch( ...
    fmAudio, ...
    audioWindow, ...
    audioOverlap, ...
    audioFFTLength, ...
    audioSampleRate);

audioPSDDB = 10*log10(audioPSD + eps);

[~,index60Hz] = min(abs(audioFrequency-60));
[~,index120Hz] = min(abs(audioFrequency-120));

fprintf("FM-audio PSD at 60 Hz:  %.2f dB/Hz\n", ...
    audioPSDDB(index60Hz))

fprintf("FM-audio PSD at 120 Hz: %.2f dB/Hz\n", ...
    audioPSDDB(index120Hz))

%% Demodulated FM audio spectrogram
spectrogramWindowLength = min( ...
    round(audioSampleRate), ...
    numel(fmAudio));

spectrogramWindow = hann(spectrogramWindowLength);
spectrogramOverlap = floor(0.75*spectrogramWindowLength);

[audioSpectrogram,audioSpectrogramFrequency, ...
    audioSpectrogramTime] = spectrogram( ...
    fmAudio, ...
    spectrogramWindow, ...
    spectrogramOverlap, ...
    audioFFTLength, ...
    audioSampleRate);

audioSpectrogramDB = ...
    20*log10(abs(audioSpectrogram) + eps);

%% Display results
figure( ...
    "Name","Recorded SDR Event Analysis", ...
    "NumberTitle","off", ...
    "Color","white", ...
    "Position",[60 40 1400 900]);

tiledlayout(3,2, ...
    "TileSpacing","compact", ...
    "Padding","compact");

% 1. Received level versus time
nexttile

plot(timeSeconds,smoothedLevelDBFS, ...
    "Color",[0 0.35 0.85])

grid on
xlabel("Time (seconds)")
ylabel("Received level (dBFS)")
title("Received Level Versus Time")
xlim([0 durationSeconds])

% 2. RF spectrum
nexttile

plot(rfFrequencyMHz,rfPSDDB, ...
    "Color",[0.00 0.35 0.75], ...
    "LineWidth",1.2)

grid on
xlabel("Frequency (MHz)")
ylabel("Power spectral density (dB/Hz)")
title("RF Spectrum")
xlim([min(rfFrequencyMHz) max(rfFrequencyMHz)])

% 3. Average 60 Hz cycle
nexttile

plot(cyclePositionMS,averageCycleDBFS, ...
    "Color",[0.8 0.1 0.1], ...
    "LineWidth",1.3)

grid on
xlabel("Position within 60 Hz cycle (ms)")
ylabel("Average power (dBFS)")
title("Average Nominal 60 Hz Cycle")
xlim([0 1000/mainsFrequency])

% 4. Rolling 60 Hz-cycle waterfall
nexttile

imagesc( ...
    cyclePositionMS, ...
    cycleStartTimeSeconds, ...
    cycleWaterfallDBFS)

axis xy
xlabel("Position within 60 Hz cycle (ms)")
ylabel("Time into recording (seconds)")
title("60 Hz-Cycle Waterfall")
colorbar
clim(waterfallColorLimits)

% 5. FM audio spectrum
nexttile

plot(audioFrequency,audioPSDDB, ...
    "Color",[0.1 0.35 0.8])

hold on
xline(60,"--r","60 Hz")
xline(120,"--m","120 Hz")
hold off

grid on
xlabel("Demodulated audio frequency (Hz)")
ylabel("Power spectral density (dB/Hz)")
title("FM Audio Spectrum")
xlim([0 500])

% 6. FM audio spectrogram
nexttile

imagesc( ...
    audioSpectrogramTime, ...
    audioSpectrogramFrequency, ...
    audioSpectrogramDB)

axis xy
xlabel("Time into recording (seconds)")
ylabel("Demodulated audio frequency (Hz)")
title("FM Audio Spectrogram")
ylim([0 300])
colorbar

sgtitle( ...
    sprintf("%s — %.6f MHz",fileName,fc/1e6), ...
    "Interpreter","none")

%% Place useful results in the base workspace
analysisResults = struct;

analysisResults.fileName = fileName;
analysisResults.centerFrequencyHz = fc;
analysisResults.sampleRate = fs;
analysisResults.durationSeconds = durationSeconds;
analysisResults.rmsDBFS = rmsDBFS;
analysisResults.medianDBFS = medianDBFS;
analysisResults.p95DBFS = p95DBFS;
analysisResults.peakDBFS = peakDBFS;
analysisResults.audio60HzPSDDB = audioPSDDB(index60Hz);
analysisResults.audio120HzPSDDB = audioPSDDB(index120Hz);

assignin("base","analysisResults",analysisResults);
%% Use white plot backgrounds with black labels
allAxes = findall(gcf,"Type","axes");

for k = 1:numel(allAxes)
    allAxes(k).Color = "white";
    allAxes(k).XColor = "black";
    allAxes(k).YColor = "black";
    allAxes(k).GridColor = [0.70 0.70 0.70];

    allAxes(k).Title.Color = "black";
    allAxes(k).XLabel.Color = "black";
    allAxes(k).YLabel.Color = "black";
end

allColorbars = findall(gcf,"Type","colorbar");

for k = 1:numel(allColorbars)
    allColorbars(k).Color = "black";
end
