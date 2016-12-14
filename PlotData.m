function PlotData(options)
close all
%% Plots
figIndex=2;
% Load data
DataFolder='AnalyzedData/';
fileListing=dir([DataFolder 'Subject*']);
for i = 1:length(fileListing)
    load([DataFolder fileListing(i).name],'SummaryData')
    PeakForces(i,:)=abs(SummaryData.PeakForces);
    MeanForce(i)=abs(SummaryData.AvgForce)*1e6; %#ok<*NASGU> % in uN
    StdForce(i)=SummaryData.StdForce*1e6; % in uN
end


%% Check statistical distribution of data

allFData=PeakForces(1,:).';
for i=1:size(PeakForces,1)
    allFData=[allFData; PeakForces(i,:).'];
    lognormalTest(i)=lillietest(log(PeakForces(i,:)),'Distr','norm'); %#ok<*AGROW>
end

% Normal distribution stats
GrandMean=mean(allFData)*1e6; %in uN

% Lognormal Stats
mu=mean(log(allFData));
sigma=std(log(allFData));
CV=sqrt(exp(sigma^2)-1);
GrandMedian=median(allFData)*1e6; % in uN
quartiles=prctile(allFData,[5,25,50,75,95])*1e6; % in uN
% lognormalTest %#ok<NOPRT>

if strcmp(options.DiagFigs,'Yes')
    figure(figIndex)
    qqplot(log(allFData)) % check for lognormal distribution
    figIndex=figIndex+1;
    
    figure(figIndex)
    set(gcf,'Position',[100 260 1037 420])
    subplot(1,2,1)
    ecdf(allFData)
    ylabel('P(F<x)')
    xlabel('Force (N)')
    subplot(1,2,2)
    ecdf(allFData)
    ylabel('P(F<x)')
    xlabel('Force (N)')
    set(gca,'XScale','log')
    suptitle('Cumulative Distribution Plots')
    figIndex=figIndex+1;
    
    figure(figIndex)
    histfit(allFData,20,'lognormal')
    figIndex=figIndex+1;
end

% compile data for plotting from small to large median
medianForces=median(PeakForces,2);
[~,I]=sort(medianForces);
plotPeaks=zeros(size(PeakForces));
for i=1:size(PeakForces,1)
    plotPeaks(i,:)=PeakForces(I(i),:);
end


%% Check to see if there is a trend within each subject
% Note that data was processed starting with the last peak from each
% subject, so we have to flip the order of the trials
ForcesInOrder=fliplr(PeakForces);
TouchNumber=1:30;
TouchNumber=TouchNumber(:); %change to column vector
if strcmp(options.DiagFigs,'Yes'); figure(figIndex); end
for i=1:size(ForcesInOrder,1)
    if strcmp(options.DiagFigs,'Yes')
        subplot(7,2,i)
        plot(ForcesInOrder(i,:))
    end
    [Rho(i),Pval(i)]=corr(TouchNumber,ForcesInOrder(i,:).'); % find Pearson's Correlation
    if strcmp(options.DiagFigs,'Yes'); title(['Rho = ',num2str(Rho(i)),', p = ',num2str(Pval(i))]); end
end

figIndex=figIndex+1;

%% Forces by volunteer

% Aesthetic parameters
axesLineWidths=2;
dataLineWidths=0.75;

% Create figure
figure1 = figure(figIndex);
set(gcf,'Units',            'inches',...
    'Position',         [0 2 3.5 3.5/1.6],... %was [0 2 3.5 3.5/1.6]
    'PaperPositionMode','auto',...
    'PaperSize',        [3.5 3.5/1.6]) %was [3.5 3.5/1.6])

% Create axes
axes1 = axes('Parent',figure1,...
    'XTickLabelMode',       'manual',...
    'XTickLabel',           ['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M'],...
    'XTick',                [1 2 3 4 5 6 7 8 9 10 11 12 13],...
    'FontSize',             12,...
    'LineWidth',            axesLineWidths,...
    'Position',             [.13 .11 .775 .79],...
    'YScale',               'log',...
    'FontName',             'Times');
xlim(axes1,[0 15]);
hold on

% Boxplot for force data
boxplot(plotPeaks.'*1e6,'whisker',9.5,...
    'Labels',{' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ' },...
    'colors','k',...
    'widths',dataLineWidths)
Whiskers=[findobj('Tag','Upper Whisker'); findobj('Tag','Lower Whisker')];
for i=1:length(Whiskers)
    set(Whiskers(i),'LineStyle','-')
end

% Create line for worm touch threshold
line([0 15],[2 2],...
    'Color',        'r',...
    'DisplayName',  ' ',...%['Worm Response Saturation: ~2 ', '\mu',  'N'],...
    'LineWidth',    dataLineWidths)

set(gca,'XTickLabelMode',       'manual',...
    'Box',                  'off',...
    'TickLength',           [0.025 0.025])
%'XTickLabel',           [],...
    %'XTick',                [],...%1 2 3 4 5 6 7 8 9 10 11 12 13 14],...

autoYLim=ylim;
ylim(axes1,[0.9 1000]);

[newX, newY]=MiriamAxes(gca,'xy');
set(newX,   'XTickLabel',   ['A'; 'B'; 'C'; 'D'; 'E' ;'F' ;'G'; 'H'; 'I'; 'J'; 'K'; 'L'; 'M'],...
            'XTick',        [1 2 3 4 5 6 7 8 9 10 11 12 13],...
            'FontName',     'Arial',...
            'FontSize',     10);
set(newY,'YTick',[1,10,100,1000]);
oldPosition=get(newY,'Position');

% Save Figures if requested
if strcmp(options.SaveFigures,'Yes')
    saveas(gcf,'VForceVsubject.eps','epsc')
    saveas(gcf,'/Users/adam/Documents/MATLAB/HairTouch2016/Figures/SubjectForceFig','pdf')
end
figIndex=figIndex+1;

%% Plot min, median, and max touches for median volunteer
% Get touches from median volunteer
medianVolunteer=fileListing(I(7)).name;
load([DataFolder medianVolunteer],'TouchStartIndex','TouchEndIndex','PeakForce')
load(['ParsedData/',medianVolunteer],'MeasuredVoltage','CantileverName','SampleRate','Gain')
load(['Cantilevers/Cantilever',CantileverName,'.mat'])
CantileverDisplacement=MeasuredVoltage./sensitivity/Gain; % in meters
medVolunteerForce=CantileverDisplacement.*k; % in Newtons
medVolunteerForce=medVolunteerForce*-1; % flip force for aesthetics

% min, median, max from this volunteer
[~,medianVolunteerSortIndex]=sort(PeakForce);
maxForceTouchEvent=1e6*medVolunteerForce(TouchStartIndex(medianVolunteerSortIndex(1)):TouchEndIndex(medianVolunteerSortIndex(1)));
maxForceTouchEventStartIndex=333-300;
maxForceTouchEvent=maxForceTouchEvent-mean(maxForceTouchEvent(1:300));

medForceTouchEvent=1e6*medVolunteerForce(TouchStartIndex(medianVolunteerSortIndex(16)):TouchEndIndex(medianVolunteerSortIndex(16)));
medForceTouchEventStartIndex=1040-300;
medForceTouchEvent=medForceTouchEvent-mean(medForceTouchEvent(1:300));

minForceTouchEvent=1e6*medVolunteerForce(TouchStartIndex(medianVolunteerSortIndex(30)):TouchEndIndex(medianVolunteerSortIndex(30)));
minForceTouchEventStartIndex=2476-300;
minForceTouchEvent=minForceTouchEvent-mean(minForceTouchEvent(1:300));


% plot all 3 together
figure(figIndex)
plotSideLength=2.5;
plotPos=[5 2 plotSideLength plotSideLength];
plotSize=[0.35 0.25 plotPos(3)-.5 plotPos(4)-.5];

set(figure(figIndex), 'Units','inches',...
    'Position',plotPos,...
    'PaperPositionMode','auto',...
    'PaperSize',[plotSideLength plotSideLength])

plotTime=0.5*SampleRate; % in number of points
TimeVector=1/SampleRate:1/SampleRate:plotTime/SampleRate;
TimeVector=TimeVector-300/SampleRate;
hold all
plot(TimeVector,maxForceTouchEvent(maxForceTouchEventStartIndex:maxForceTouchEventStartIndex+plotTime-1),'Color',[27,158,119]/255)
plot(TimeVector,medForceTouchEvent(medForceTouchEventStartIndex:medForceTouchEventStartIndex+plotTime-1),'Color',[217,95,2]/255)
plot(TimeVector,minForceTouchEvent(minForceTouchEventStartIndex:minForceTouchEventStartIndex+plotTime-1),'Color',[117,112,179]/255)

set(gca,'Box','off','Units','inches',...
    'ActivePositionProperty','Position',...
    'Position',plotSize)
xlim([TimeVector(1) TimeVector(end)])
MiriamAxes(gca,'xy');

% Save Figures if requested
if strcmp(options.SaveFigures,'Yes')
    saveas(gcf,'ExampleTouch.eps','epsc')
    saveas(gcf,'/Users/adam/Documents/MATLAB/HairTouch2016/Figures/ExampleTouch','pdf')
end
figIndex=figIndex+1;

%% Plot cdf of min, median, and max volunteers
% Gather data
minVolunteer=fileListing(I(1)).name;
load([DataFolder minVolunteer],'PeakForce')
minVolunteerForces=-PeakForce;

medVolunteer=fileListing(I(7)).name;
load([DataFolder medVolunteer],'PeakForce')
medVolunteerForces=-PeakForce;
SortedForces=sort(medVolunteerForces)*1e6;

maxVolunteer=fileListing(I(13)).name;
load([DataFolder maxVolunteer],'PeakForce')
maxVolunteerForces=-PeakForce;

% plot all 3 together
figure(figIndex)
hold all
plotSideLength=2.5;
plotPos=[8 2 plotSideLength plotSideLength];
plotSize=[0.35 0.25 plotPos(3)-.5 plotPos(4)-.5];

set(figure(figIndex), 'Units','inches',...
    'Position',plotPos,...
    'PaperPositionMode','auto',...
    'PaperSize',[plotSideLength plotSideLength])

[cdff, x]=ecdf(minVolunteerForces*1e6);
plot(x,cdff,'Color','k')%[27,158,119]/255)
[cdff, x]=ecdf(medVolunteerForces*1e6);
plot(x,cdff,'Color','k')%[217,95,2]/255)
[cdff, x]=ecdf(maxVolunteerForces*1e6);
plot(x,cdff,'Color','k')%[117,112,179]/255)

% mark trials plotted in Fig 2B
plot(SortedForces(1),1/30,'o','Color',[117,112,179]/255)
plot(SortedForces(16),16/30,'o','Color',[217,95,2]/255)
plot(SortedForces(30),1,'o','Color',[27,158,119]/255)

set(gca,'XScale','log')
MiriamAxes(gca,'xy');

% Save Figures if requested
if strcmp(options.SaveFigures,'Yes')
    saveas(gcf,'/Users/adam/Documents/MATLAB/HairTouch2016/Figures/CDFofMinMedMax','pdf')
end
figIndex=figIndex+1;


%% Save plots with data from all touches, if requested
if strcmp(options.SaveFigures,'Yes') && strcmp(options.DiagFigs,'Yes')
    AnalyzedDataFiles=dir('AnalyzedData/Subject*');
    ParsedDataFiles=dir('ParsedData/Subject*');
    for i=1:length(AnalyzedDataFiles)
        load(['AnalyzedData/',AnalyzedDataFiles(i).name],'TouchStartIndex','TouchEndIndex')
        load(['ParsedData/',AnalyzedDataFiles(i).name],'MeasuredVoltage','CantileverName','SampleRate','Gain')
        
        load(['Cantilevers/Cantilever',CantileverName,'.mat'])
        CantileverDisplacement=MeasuredVoltage./sensitivity/Gain; % in meters
        Force=CantileverDisplacement.*k; % in Newtons
        
        figure(figIndex)
        set(gcf,'Position',[1 64 1280 641])
        suptitle(['Touch Event for Subject ',AnalyzedDataFiles(i).name(end-4)])
        for j=1:length(TouchStartIndex)
            subplot(5,6,j)
            plot(1/SampleRate:1/SampleRate:(TouchEndIndex(j)-TouchStartIndex(j)+1)/SampleRate,Force(TouchStartIndex(j):TouchEndIndex(j))*1e6,'k')
            xlabel('Time (s)')
            ylabel('Force(uN')
        end
        
        saveas(gcf,['/Users/adam/Documents/MATLAB/HairTouch2016/TouchEventPlots/',AnalyzedDataFiles(i).name(1:end-4)],'pdf')
        
        figIndex=figIndex+1;
    end
end

end
