% Analyze Hair Touch Data
% Copyright Adam Nekimken, 2016

clear all
close all

options = AnalysisOptions

ParseRawData(options);
% if strcmp(options.ParseData,'Yes')
%     run('ParseRawData')
% end

DataAnalysis(options);
% if strcmp(options.DoDataAnalysis,'Yes')
%     run('DataAnalysis')
% end

PlotData(options)

%{
%% Analyze data
if strcmp(options.DoDataAnalysis,'Yes')
    %% Find touches in data
    
    TouchDuration=1*SampleRate; %assume size of touch
    
    TouchStart=zeros(30,1); % index of touch start
    TouchEnd=zeros(30,1); % index of touch end
    PeakList=zeros(30,1); % coordinates of peak within touch bounds
    Offset=zeros(30,1); % offset due to unbalanced bridge
    
    %     for i = options.DatasetToStartWith:length(fileListing)
    index=length(Voltage);
    NumPeaksDetected=0;
    
    % filter to remove ringing and line noise
    filteredData=filter_60HzBandStop(Voltage);
    filteredData=filter_1400HzBandstop(filteredData);
    filteredData=filter_5HzHighPass(filteredData);
    
    % set peak detection based on noise in baseline signal
    DetectionThreshold=3*std(Voltage(3000:8000)); %note: start at 3000th data point to avoid filtering artifact
    
    % create figure with filtered data, raw data, and detection threshold plotted
    peakFig=figure('Position',[1 69 1280 636]);
    plot(Voltage)
    hold all
    plot(filteredData)
    line([1 length(Voltage)],[DetectionThreshold, DetectionThreshold],'Color','k')
    line([1 length(Voltage)],[-DetectionThreshold, -DetectionThreshold],'Color','k')
    
    % find 30 peaks and plot them for confirmation as they are found
    EachTouchFig=figure; % figure for plotting each of the 30 touches individually
    set(EachTouchFig,'Position',[1281 316 1920 789])
    while NumPeaksDetected<30 % for each section of filtered data
        
        if index-TouchDuration<=0 % check if we're done
            break
            
        elseif filteredData(index)<-DetectionThreshold &&...% if signal exceeds noise threshold
                all(filteredData(index-TouchDuration-0.2*TouchDuration:index-TouchDuration)<DetectionThreshold*1) % and is far enough from other touches to get baseline
            
            % Record information about peaks
            NumPeaksDetected=NumPeaksDetected+1; %found one!
            TouchEnd(NumPeaksDetected)=index;  % peak detected, record this part of signal as peak
            TouchStart(NumPeaksDetected)=index-TouchDuration;
            
            % Get Offset
            OffsetWindowSize=2*round(500/2);
            Offset(NumPeaksDetected)=mean(Voltage(TouchStart(NumPeaksDetected)-OffsetWindowSize/2:TouchStart(NumPeaksDetected)+OffsetWindowSize/2)); % mean value of 500 points at start of touch
            
            % get value of peak as minumum voltage in this span
            % Uses minimum because downward forces negative volts in this case
            % Corrects for offset
            PeakList(NumPeaksDetected)=min(Voltage(TouchStart(NumPeaksDetected):TouchEnd(NumPeaksDetected)))-Offset(NumPeaksDetected);
            
            % plot detected peak
            figure(peakFig)
            xlim([index-3*SampleRate index+3*SampleRate])
            pk=plot(TouchEnd(NumPeaksDetected),0,'Marker','<','LineStyle','none','Color','r','MarkerFaceColor','r');
            start=plot(TouchStart(NumPeaksDetected),0,'Marker','>','LineStyle','none','Color','r','MarkerFaceColor','r');
            offsetStart=plot(TouchStart(NumPeaksDetected)-OffsetWindowSize/2,0,'Marker','<','LineStyle','none','Color','k','MarkerFaceColor','k');
            offsetEnd=plot(TouchStart(NumPeaksDetected)+OffsetWindowSize/2,0,'Marker','>','LineStyle','none','Color','k','MarkerFaceColor','k');
            
            
            % ask user to confirm validity of peak
            prompt = 'Good peak? Enter "m" for manual correction or nothing for good peak - ';
            str = input(prompt,'s');
            
            if isempty(str)
                % plot individual touch with other touches
                figure(EachTouchFig)
                subplot(6,5,NumPeaksDetected)
                plot(1/5000:1/5000:TouchDuration/SampleRate,Voltage(TouchStart(NumPeaksDetected):TouchEnd(NumPeaksDetected)-1))
                xlabel('Time (s)')
                ylabel('Voltage (V)')
                
                index=index-TouchDuration; %move one touch duration backwards
                
            elseif strcmp(str,'m') % manual peak find
                disp('Click end of touch after ringdown.')
                DoneWithManualFind=false;
                while DoneWithManualFind==false
                    figure(peakFig)
                    [x,y]=ginput(1);
                    % update touch boundaries
                    TouchEnd(NumPeaksDetected)=round(x);
                    TouchStart(NumPeaksDetected)=TouchEnd(NumPeaksDetected)-TouchDuration;
                    
                    % Update value of peak
                    % Get Offset
                    OffsetWindowSize=2*round(500/2);
                    Offset(NumPeaksDetected)=mean(Voltage(TouchStart(NumPeaksDetected)-OffsetWindowSize/2:TouchStart(NumPeaksDetected)+OffsetWindowSize/2)); % mean value of 500 points at start of touch
                    
                    % get value of peak as minumum voltage in this span
                    % Uses minimum because downward forces negative volts in this case
                    % Corrects for offset
                    PeakList(NumPeaksDetected)=min(Voltage(TouchStart(NumPeaksDetected):TouchEnd(NumPeaksDetected)))-Offset(NumPeaksDetected);
                    
                    % plot user's touch bounds
                    delete(pk) % get rid of auto-detected touch from before
                    delete(start)
                    delete(offsetStart)
                    delete(offsetEnd)
                    pk=plot(TouchEnd(NumPeaksDetected),0,'Marker','<','LineStyle','none','Color','r','MarkerFaceColor','r');
                    start=plot(TouchStart(NumPeaksDetected),0,'Marker','>','LineStyle','none','Color','r','MarkerFaceColor','r');
                    offsetStart=plot(TouchStart(NumPeaksDetected)-OffsetWindowSize/2,0,'Marker','<','LineStyle','none','Color','k','MarkerFaceColor','k');
                    offsetEnd=plot(TouchStart(NumPeaksDetected)+OffsetWindowSize/2,0,'Marker','>','LineStyle','none','Color','k','MarkerFaceColor','k');
                    
                    % Check to make sure new touch is better
                    prompt = 'Is this better? Yes: 1, No: default, Bad peak: 0 - ' ;
                    answer = input(prompt,'s');
                    
                    if strcmp(answer,'1')
                        figure(EachTouchFig)
                        subplot(6,5,NumPeaksDetected)
                        plot(1/5000:1/5000:TouchDuration/SampleRate,Voltage(TouchStart(NumPeaksDetected):TouchEnd(NumPeaksDetected)-1))
                        xlabel('Time (s)')
                        ylabel('Voltage (V)')
                        
                        DoneWithManualFind=true;
                        index=TouchStart(NumPeaksDetected); %move one touch duration backwards
                        
                    elseif strcmp(answer,'0')
                        NumPeaksDetected=NumPeaksDetected-1; %remove bad peak
                        index=index-1000; % move a bit to look for next peak
                    end
                    
                    
                end
            else
                NumPeaksDetected=NumPeaksDetected-1; %remove bad peak
                index=index-1000; % move a bit to look for next peak
            end
            
            % clean up markers on plot
            delete(pk)
            delete(start)
            delete(offsetStart)
            delete(offsetEnd)
            
        else % if we didn't find a peak, continue looking
            index=index-1;
        end
    end
    
    % clean up for next Subject and save if desired
    if strcmp(options.SaveFigures,'Yes')
        savefig(EachTouchFig,['TouchEventPlots/TouchEvents', fileListing.name(1:end-5)])
    end
    close(EachTouchFig)
    
%     SubjectTouchEnds=TouchEnd;
%     SubjectTouchStarts=TouchStart;
%     SubjectPeaks=PeakList;
%     SubjectOffsets=Offset;
%     if strcmp(options.SaveData,'Yes')
%         save(['AnalyzedData/' fileListing.name(1:end-4)],'SubjectTouchEnds','SubjectTouchStarts','SubjectPeaks','SubjectOffsets')
%     end
    %     end
    
    
    %% Calculate Forces
    CantileverDisplacement=cell(size(Voltage));
    MaxForce=zeros(30,1);
    
    for i = 1:length(fileListing)
        load(['Cantilevers/',Cantilever,'.mat'])
        CantileverDisplacement=PeakList./sensitivity; % in meters
        MaxForce=CantileverDisplacement.*k; % in Newtons
    end
    
    %% Statistical Analysis
    AvgForce=mean(MaxForce); 
    StdForce=std(MaxForce);
    
    GrandMeanForce=mean(AvgForce);
    %PooledVarianceForce=
    
    
    if strcmp(options.SaveData,'Yes')
        save(['AnalyzedData/' fileListing.name(1:end-4)],'TouchEnd','TouchStart','PeakList','Offset','Force','CantileverDisplacement')
    end
end

%% Plots
% Load data
DataFolder='AnalyzedData/';
fileListing=dir([DataFolder 'Subject*']);
for i = 2:length(fileListing)
    load([DataFolder fileListing(i).name])
    Peaks(i,:)=SubjectPeaks; %#ok<SAGROW>
    %     Touches{i}=(1:length(MeasuredVoltage))./SampleRate; %#ok<SAGROW>
    %     Cantilever{i}=CantileverName; %#ok<SAGROW>
end

% Forces by volunteer
ForcePlot=figure;
bar(Peaks,'w')
errorbar(mean(Peaks),std(StdForce),'LineStyle','none','Color','k')

%}

