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
    %     Touches{i}=(1:length(MeasuredVoltage))./SampleRate; %#ok<SAGROW>
    %     Cantilever{i}=CantileverName; %#ok<SAGROW>
end
 

%% Check statistical distribution of data
figure(figIndex)
allFData=PeakForces(1,:).';
for i=1:size(PeakForces,1)
    allFData=[allFData; PeakForces(i,:).']; 
    lognormalTest(i)=lillietest(log(PeakForces(i,:)),'Distr','norm'); %#ok<*AGROW>
end
lognormalTest %#ok<NOPRT>
qqplot(log(allFData)) % check for lognormal distribution
figIndex=figIndex+1; 

% Lognormal Stats
mu=mean(log(allFData));
sigma=std(log(allFData));
CV=sqrt(exp(sigma^2)-1);
GrandMedian=median(allFData)*1e6; % in uN
quartiles=prctile(allFData,[5,25,50,75,95])*1e6; % in uN

figure(figIndex)
histfit(allFData,20,'lognormal')
figIndex=figIndex+1; 

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
figure(figIndex)
for i=1:size(ForcesInOrder,1)
    subplot(7,2,i)
    plot(ForcesInOrder(i,:))
    [Rho(i),Pval(i)]=corr(TouchNumber,ForcesInOrder(i,:).'); % find Pearson's Correlation
    title(['Rho = ',num2str(Rho(i)),', p = ',num2str(Pval(i))])
end

figIndex=figIndex+1;

%% Forces by volunteer

% Aesthetic parameters
axesLineWidths=2;
dataLineWidths=0.75;

% Create figure
figure1 = figure(figIndex);
set(gcf,'Units',            'inches',...
        'Position',         [0 2 5 3.5/1.6],... %was [0 2 3.5 3.5/1.6]
        'PaperPositionMode','auto',...
        'PaperSize',        [5 3.5/1.6]) %was [3.5 3.5/1.6])
    
% Create axes
axes1 = axes('Parent',figure1,...
    'XTickLabelMode',       'manual',...
    'XTickLabel',           [],...
    'XTick',                [1 2 3 4 5 6 7 8 9 10 11 12 13 14],...
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
    'XTickLabel',           [],...
    'XTick',                [],...%1 2 3 4 5 6 7 8 9 10 11 12 13 14],...
    'Box',                  'off',...
    'TickLength',           [0.025 0.025])

autoYLim=ylim;
ylim(axes1,[0.9 1000]);

[newX, newY]=MiriamAxes(gca,'y');
set(newX,'XTick',[]);
set(newX,'Visible','off');
set(newY,'YTick',[1,10,100,1000]);
oldPosition=get(newY,'Position');

% Save Figures if requested
if strcmp(options.SaveFigures,'Yes')
    saveas(gcf,'VForceVsubject.eps','epsc')
    saveas(gcf,'/Users/adam/Documents/MATLAB/HairTouch2016/Figures/SubjectForceFig','pdf')
end
figIndex=figIndex+1; 

%% Get one touch for panel in figure
openfig('TouchEventPlots/TouchEventsSubject.fig','new','invisible')
AllAxes=get(gcf,'Children');
dataObjs=get(AllAxes(6),'Children');

xData=get(dataObjs,'XData');
yData=get(dataObjs,'YData');

load('Cantilevers/Cantilever3B.mat')
CantileverDisplacement=yData./sensitivity/1000; % in meters
Force=CantileverDisplacement.*k*1e6; % in uN
Force=Force*-1; % flip sign for aesthetics
Force=Force-mean(Force(1:2000)); % baseline correction
Time=xData-.357; % set time=0 to initial contact

figure(figIndex)
plotWidth=4;
plotPos=[5 2 plotWidth plotWidth/1.6];
plotSize=[0.35 0.25 plotPos(3)-.5 plotPos(4)-.5];

set(figure(figIndex), 'Units','inches',...
    'Position',plotPos,...
    'PaperPositionMode','auto',...
    'PaperSize',[plotWidth plotWidth/1.6])

plot(Time,Force,'k')
set(gca,'Box','off','Units','inches',...
    'ActivePositionProperty','Position',...
    'Position',plotSize)
xlim([-.2 1])
MiriamAxes(gca,'xy');


% Save Figures if requested
if strcmp(options.SaveFigures,'Yes')
    saveas(gcf,'ExampleTouch.eps','epsc')
    saveas(gcf,'/Users/adam/Documents/MATLAB/HairTouch2016/Figures/ExampleTouch','pdf')
end
figIndex=figIndex+1; 

%% Make plots with data from all touches
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
    
    % Save Figures if requested
    if strcmp(options.SaveFigures,'Yes')
        saveas(gcf,['/Users/adam/Documents/MATLAB/HairTouch2016/TouchEventPlots/',AnalyzedDataFiles(i).name(1:end-4)],'pdf')
    end
    figIndex=figIndex+1;
end


end
