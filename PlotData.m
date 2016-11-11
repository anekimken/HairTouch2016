function PlotData(options)

%% Plots
% Load data
DataFolder='AnalyzedData/';
fileListing=dir([DataFolder 'Subject*']);
for i = 2:length(fileListing)
    load([DataFolder fileListing(i).name])
    Peaks(i,:)=SubjectPeaks;  %#ok<AGROW>
    %     Touches{i}=(1:length(MeasuredVoltage))./SampleRate; %#ok<SAGROW>
    %     Cantilever{i}=CantileverName; %#ok<SAGROW>
end

% Forces by volunteer
ForcePlot=figure;
bar(Peaks,'w')
errorbar(mean(Peaks),std(StdForce),'LineStyle','none','Color','k')

end