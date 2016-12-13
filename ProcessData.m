function ProcessData(options)
if strcmp(options.ProcessData,'Yes')
    %% Import data
    
    DataFolder='ParsedData/';
    fileListing=dir([DataFolder options.Filename]);
    load([DataFolder fileListing.name])
    Voltage=MeasuredVoltage;
    Time=(1:length(MeasuredVoltage))./SampleRate;
    Cantilever=CantileverName;
    
    %% Find touches in data
    
    % Input parameters
    TouchDuration=1.5*SampleRate; %assume size of touch, by number of points
    OffsetWindowSize=2*round(500/2); % length of data to use to calculate DC offset
    
    % Initialize data structures
    TouchStartIndex=zeros(30,1); % index of touch start
    TouchEndIndex=zeros(30,1); % index of touch end
    PeakList=zeros(30,1); % coordinates of peak within touch bounds
    Offset=zeros(30,1); % offset due to unbalanced bridge
    ManuallyAdjusted=zeros(30,1);
    index=length(Voltage);
    NumPeaksDetected=0;
    
    % filter to remove ringing and line noise
    filteredData=filter_60HzBandStop(Voltage);
    filteredData=filter_1400HzBandstop(filteredData);
    filteredData=filter_5HzHighPass(filteredData);
    
    % set peak detection based on noise in baseline signal
    DetectionThreshold=3*std(Voltage(3000:8000)); %note: start at 3000th data point to avoid filtering artifact
    % Calculate Forces at detection threshold
    load(['Cantilevers/Cantilever',Cantilever,'.mat'])
    DispThreshold=DetectionThreshold/sensitivity/Gain; % in meters
    ForceThreshold=DispThreshold*k; %#ok<NASGU> % in Newtons 
    
    
    % create figure with filtered data, raw data, and detection threshold plotted
    peakFig=figure('Position',[1 69 1280 636]);
    plot(Time,Voltage)
    hold all
    plot(Time,filteredData)
    line([1 length(Voltage)],[DetectionThreshold, DetectionThreshold],'Color','k')
    line([1 length(Voltage)],[-DetectionThreshold, -DetectionThreshold],'Color','k')
    
    % find 30 peaks and plot them for confirmation as they are found
    EachTouchFig=figure; % figure for plotting each of the 30 touches individually
    set(EachTouchFig,'Position',[1281 316 1920 789])
    while NumPeaksDetected<30 % for each section of filtered data
        if index-TouchDuration<=0 % check if we're done
            break
            
        elseif filteredData(index)<-DetectionThreshold &&...% if signal exceeds noise threshold
                std(Voltage(index-TouchDuration-OffsetWindowSize/2:index-TouchDuration+OffsetWindowSize/2))<DetectionThreshold*1 &&... % and is far enough from other touches to get baseline
                index+3*SampleRate<length(Time)
            
            % Record information about peaks
            NumPeaksDetected=NumPeaksDetected+1; %found one!
            TouchEndIndex(NumPeaksDetected)=index;  % peak detected, record this part of signal as peak
            TouchStartIndex(NumPeaksDetected)=index-TouchDuration;
            
            % Get Offset
            Offset(NumPeaksDetected)=mean(Voltage(TouchStartIndex(NumPeaksDetected)-OffsetWindowSize/2:TouchStartIndex(NumPeaksDetected)+OffsetWindowSize/2)); % mean value of 500 points at start of touch
            
            % get value of peak as minumum voltage in this span
            % Uses minimum because downward forces negative volts in this case
            % Corrects for offset
            PeakList(NumPeaksDetected)=min(Voltage(TouchStartIndex(NumPeaksDetected):TouchEndIndex(NumPeaksDetected)))-Offset(NumPeaksDetected);
            
            % show range of detected peak
            figure(peakFig)
            xlim([Time(index-3*SampleRate) Time(index+3*SampleRate)])
            pk=plot(Time(TouchEndIndex(NumPeaksDetected)),0,'Marker','<','LineStyle','none','Color','r','MarkerFaceColor','r');
            start=plot(Time(TouchStartIndex(NumPeaksDetected)),0,'Marker','>','LineStyle','none','Color','r','MarkerFaceColor','r');
            
            % show range used for finding offset
            offsetStart=plot(Time(TouchStartIndex(NumPeaksDetected)-OffsetWindowSize/2),0,'Marker','<','LineStyle','none','Color','k','MarkerFaceColor','k');
            offsetEnd=plot(Time(TouchStartIndex(NumPeaksDetected)+OffsetWindowSize/2),0,'Marker','>','LineStyle','none','Color','k','MarkerFaceColor','k');
            
            
            % ask user to confirm validity of peak
            % Things to check for:
            %   -Is the peak in the right direction?
            %   -Is the peak contained within the bounds?
            %   -Is the detected peak just passband ripple or other filtering artifact?
            prompt = 'Good peak? Enter "m" for manual correction or nothing for good peak - ';
            str = input(prompt,'s');
            
            if isempty(str)
                % plot individual touch with other touches
                figure(EachTouchFig)
                subplot(6,5,NumPeaksDetected)
                plot(1/SampleRate:1/SampleRate:TouchDuration/SampleRate,Voltage(TouchStartIndex(NumPeaksDetected):TouchEndIndex(NumPeaksDetected)-1))
                xlabel('Time (s)')
                ylabel('Voltage (V)')
                
                index=index-TouchDuration; %move one touch duration backwards
                
            elseif strcmp(str,'m') % manual peak find
                disp('Click end of touch after ringdown.')
                ManuallyAdjusted(NumPeaksDetected)=1;
                DoneWithManualFind=false;
                while DoneWithManualFind==false
                    figure(peakFig)
                    [x,~]=ginput(1);
                    % update touch boundaries
                    TouchEndIndex(NumPeaksDetected)=round(x*SampleRate);
                    TouchStartIndex(NumPeaksDetected)=TouchEndIndex(NumPeaksDetected)-TouchDuration;
                    
                    % Update value of peak
                    % Get Offset
                    OffsetWindowSize=2*round(500/2);
                    Offset(NumPeaksDetected)=mean(Voltage(TouchStartIndex(NumPeaksDetected)-OffsetWindowSize/2:TouchStartIndex(NumPeaksDetected)+OffsetWindowSize/2)); % mean value of 500 points at start of touch
                    
                    % get value of peak as minumum voltage in this span
                    % Uses minimum because downward forces negative volts in this case
                    % Corrects for offset
                    PeakList(NumPeaksDetected)=min(Voltage(TouchStartIndex(NumPeaksDetected):TouchEndIndex(NumPeaksDetected)))-Offset(NumPeaksDetected);
                    
                    % plot user's touch bounds
                    delete(pk) % get rid of auto-detected touch from before
                    delete(start)
                    delete(offsetStart)
                    delete(offsetEnd)
                    pk=plot(Time(TouchEndIndex(NumPeaksDetected)),0,'Marker','<','LineStyle','none','Color','r','MarkerFaceColor','r');
                    start=plot(Time(TouchStartIndex(NumPeaksDetected)),0,'Marker','>','LineStyle','none','Color','r','MarkerFaceColor','r');
                    offsetStart=plot(Time(TouchStartIndex(NumPeaksDetected)-OffsetWindowSize/2),0,'Marker','<','LineStyle','none','Color','k','MarkerFaceColor','k');
                    offsetEnd=plot(Time(TouchStartIndex(NumPeaksDetected)+OffsetWindowSize/2),0,'Marker','>','LineStyle','none','Color','k','MarkerFaceColor','k');
                    
                    % Check to make sure new touch is better
                    prompt = 'Is this better? Yes: 1, No: default, Bad peak: 0 - ' ;
                    answer = input(prompt,'s');
                    
                    if strcmp(answer,'1')
                        figure(EachTouchFig)
                        subplot(6,5,NumPeaksDetected)
                        plot(1/5000:1/5000:TouchDuration/SampleRate,Voltage(TouchStartIndex(NumPeaksDetected):TouchEndIndex(NumPeaksDetected)-1))
                        xlabel('Time (s)')
                        ylabel('Voltage (V)')
                        
                        DoneWithManualFind=true;
                        index=TouchStartIndex(NumPeaksDetected); %move one touch duration backwards
                        
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
        savefig(EachTouchFig,['TouchEventPlots/TouchEvents', fileListing.name(1:end)])
        disp('Savings touch events fig')
    end
    close(EachTouchFig)
    
    
    
    %% Calculate Forces from cantilever parameters
    load(['Cantilevers/Cantilever',Cantilever,'.mat'])
    CantileverDisplacement=PeakList./sensitivity/Gain; % in meters
    PeakForce=CantileverDisplacement.*k; % in Newtons
    
    %% Statistical Analysis
    AvgForce=mean(PeakForce);
    StdForce=std(PeakForce);
    
    
    %% Data structure for saving to enable easy analysis
    SummaryData=struct('PeakForces',PeakForce,'AvgForce',AvgForce,'StdForce',StdForce); %#ok<NASGU>
    
    if strcmp(options.SaveData,'Yes')
        save(['AnalyzedData/' fileListing.name(1:end-4)],'SummaryData','TouchEndIndex','TouchStartIndex','PeakList','Offset','PeakForce','CantileverDisplacement','AvgForce','StdForce')
    end
end


end