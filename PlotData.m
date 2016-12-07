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
% mu=mean(log(allFData));
% sigma=std(log(allFData));
% lognlike([mu,sigma],allFData)
figure(figIndex)
histfit(allFData,20,'lognormal')
figIndex=figIndex+1; 


medianForces=median(PeakForces,2);
[~,I]=sort(medianForces);
plotPeaks=zeros(size(PeakForces));
figure(figIndex)
hold on
for i=1:size(PeakForces,1)
    plotPeaks(i,:)=PeakForces(I(i),:);
    plot(i,PeakForces(I(i),:),'linestyle','none','marker','x','Color','k')
end
set(gca,'YScale','log')
figIndex=figIndex+1; 


%% Forces by volunteer

% Aesthetic parameters
axesLineWidths=2;
dataLineWidths=0.75;

% Create figure
figure1 = figure(figIndex);
set(gcf,'Units',            'inches',...
        'Position',         [0 2 7 3.5/1.6],... %was [0 2 3.5 3.5/1.6]
        'PaperPositionMode','auto',...
        'PaperSize',        [7 3.5/1.6]) %was [3.5 3.5/1.6])

    
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
% ,...
%     'Units',                'inches',...
%     'Position',             [1.2 .3 7 4]
xlim(axes1,[0 15]);


hold on
%bar graph for force data
% bar(MeanForce,'w',...
%     'DisplayName',  ' ',...%'Applied Force',...
%     'LineWidth',    dataLineWidths,...
%     'ShowBaseline','off');

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

% Create legend
% [legh,~,~,~] = legend('Location',     'NorthWest');
% oldPosition=get(legh,'Position'); %#ok<NASGU>
% set(legh,'LineWidth',axesLineWidths,...
%     'Interpreter',  'tex',...
%     'Position',     [0.1528    0.7    0.2    0.2452],...%oldPosition+[0 0.05 -0.1 0],...
%     'FontSize',     1)
% legend(gca, 'boxoff')


% Create errorbar
% errorbar(MeanForce,StdForce/sqrt(30),'MarkerSize',10,'MarkerFaceColor','none',...
%     'MarkerEdgeColor',[0 0 0],...
%     'Marker','none',...
%     'LineStyle','none',...
%     'LineWidth',dataLineWidths,...
%     'Color',[0 0 0]);

set(gca,'XTickLabelMode',       'manual',...
    'XTickLabel',           [],...
    'XTick',                [],...%1 2 3 4 5 6 7 8 9 10 11 12 13 14],...
    'Box',                  'off',...
    'TickLength',           [0.025 0.025])

autoYLim=ylim;
ylim(axes1,[0.9 1000]);


[newX, newY]=MiriamAxes(gca,'y');
set(newX,'XTick',[]);
set(newY,'YTick',[1,10,100,1000]);
oldPosition=get(newY,'Position');
% set(newY,'Position',[oldPosition(1) oldPosition(2) oldPosition(3) oldPosition(4)-.025]);



if strcmp(options.SaveFigures,'Yes')
    saveas(gcf,'VForceVsubject.eps','epsc')
    saveas(gcf,'/Users/adam/Documents/MATLAB/HairTouch2016/Figures/SubjectForceFig','pdf')
end
figIndex=figIndex+1; 


end
