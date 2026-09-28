%% Replay a saved road-noise IQ event through the monitor display
% SPACE pauses/resumes; R restarts; Q quits.
clearvars;
close all;

%% Select recording
[fileName,filePath]=uigetfile({'*.mat','MATLAB data files (*.mat)'}, ...
    'Select a road event to replay');
if isequal(fileName,0), return; end
D=load(fullfile(filePath,fileName));
required={'eventIQ','fs','fc'};
for k=1:numel(required)
    if ~isfield(D,required{k})
        error('Selected file does not contain %s.',required{k});
    end
end

rawIQ=D.eventIQ(:);
fs=double(D.fs); fc=double(D.fc);
mainsFrequency=60; historySeconds=3;
displayColumns=500; displayUpdatesPerSecond=10;
samplesPerCycle=round(fs/mainsFrequency);
historyCycles=round(historySeconds*mainsFrequency);
displayEveryCycles=max(1,round(mainsFrequency/displayUpdatesPerSecond));
assert(mod(samplesPerCycle,displayColumns)==0, ...
    'Sample rate is incompatible with the 500-column display.');
samplesPerPixel=samplesPerCycle/displayColumns;
cycleTimeMS=(0:samplesPerCycle-1)*1000/fs;
displayTimeMS=((0:displayColumns-1)+0.5)* ...
    (1000/mainsFrequency)/displayColumns;
waterfallAgeSeconds=linspace(historySeconds,0,historyCycles);
numberCycles=floor(numel(rawIQ)/samplesPerCycle);

%% Apply the same 100 kHz channel filter as the live monitor
channelFilter=dsp.LowpassFilter(SampleRate=fs,PassbandFrequency=45e3, ...
    StopbandFrequency=55e3,PassbandRipple=0.5,StopbandAttenuation=60);
filteredIQ=channelFilter(rawIQ);
release(channelFilter);
envelopeDBFS=20*log10(abs(filteredIQ)+eps('single'));

%% Display
waterfallData=-90*ones(historyCycles,displayColumns,'single');
fig=figure(Name='Road Event Replay',NumberTitle='off',Color='black', ...
    WindowKeyPressFcn=@keyPress);
setappdata(fig,'Paused',false);
setappdata(fig,'RestartRequested',false);
setappdata(fig,'StopRequested',false);

layout=tiledlayout(fig,2,1,TileSpacing='compact',Padding='compact');
ax1=nexttile(layout,1);
trace=plot(ax1,cycleTimeMS,-90*ones(size(cycleTimeMS)), ...
    Color=[1 .85 0],LineWidth=1);
grid(ax1,'on'); xlim(ax1,[0 1000/mainsFrequency]); ylim(ax1,[-80 0]);
xlabel(ax1,'Position within 60 Hz cycle (ms)');
ylabel(ax1,'Amplitude (dBFS)');
ax1.Color='black'; ax1.XColor='white'; ax1.YColor='white';
statusText=text(ax1,.02,.90,'SPACE pause | R restart | Q quit', ...
    Units='normalized',VerticalAlignment='top',FontSize=12, ...
    FontWeight='bold',Color=[.7 .7 .7]);

ax2=nexttile(layout,2);
waterfallImage=imagesc(ax2,displayTimeMS,waterfallAgeSeconds,waterfallData);
ax2.YDir='normal'; ax2.Color='black'; ax2.XColor='white'; ax2.YColor='white';
xlabel(ax2,'Position within 60 Hz cycle (ms)'); ylabel(ax2,'Age (seconds)');
title(ax2,'Rolling 60 Hz-cycle waterfall'); colormap(ax2,turbo);
clim(ax2,[-65 -20]); colorbar(ax2,'Color','white');

gpsText='GPS not stored';
if isfield(D,'gpsFix') && isfield(D.gpsFix,'Valid') && D.gpsFix.Valid
    gpsText=sprintf('GPS %.6f, %.6f',D.gpsFix.Latitude,D.gpsFix.Longitude);
end

%% Real-time replay loop
cycleNumber=1;
while isgraphics(fig) && ~getappdata(fig,'StopRequested')
    if getappdata(fig,'RestartRequested')
        cycleNumber=1;
        waterfallData(:)=-90;
        waterfallImage.CData=waterfallData;
        setappdata(fig,'RestartRequested',false);
    end

    if getappdata(fig,'Paused')
        statusText.String='PAUSED | SPACE resume | R restart | Q quit';
        drawnow;
        pause(0.05);
        continue
    end

    if cycleNumber>numberCycles
        statusText.String='END | R restart | Q quit';
        setappdata(fig,'Paused',true);
        drawnow;
        continue
    end

    first=(cycleNumber-1)*samplesPerCycle+1;
    last=first+samplesPerCycle-1;
    oneCycle=envelopeDBFS(first:last);
    row=max(reshape(oneCycle,samplesPerPixel,displayColumns),[],1);
    waterfallData(1:end-1,:)=waterfallData(2:end,:);
    waterfallData(end,:)=row;

    if mod(cycleNumber-1,displayEveryCycles)==0
        trace.YData=oneCycle;
        waterfallImage.CData=waterfallData;
        elapsed=(cycleNumber-1)/mainsFrequency;
        title(ax1,sprintf('%.4f MHz | Replay %.1f / %.1f s | %s', ...
            fc/1e6,elapsed,numberCycles/mainsFrequency,gpsText));
        statusText.String='PLAYING | SPACE pause | R restart | Q quit';
        drawnow;
        pause(displayEveryCycles/mainsFrequency);
    end
    cycleNumber=cycleNumber+1;
end

%% Keyboard controls
function keyPress(fig,event)
switch lower(event.Key)
    case 'space'
        setappdata(fig,'Paused',~getappdata(fig,'Paused'));
    case 'r'
        setappdata(fig,'RestartRequested',true);
        setappdata(fig,'Paused',false);
    case 'q'
        setappdata(fig,'StopRequested',true);
end
end

