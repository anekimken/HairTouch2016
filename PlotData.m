function PlotData(options)
close all
%% Plots
figIndex=2;
% Load data
DataFolder='AnalyzedData/';
fileListing=dir([DataFolder 'Subject*']);
for i = 1:length(fileListing)
    load([DataFolder fileListing(i).name],'SummaryData')
    Peaks(i,:)=abs(SummaryData.PeakForces);  
    MeanForce(i)=abs(SummaryData.AvgForce)*1e6; % in uN   
    StdForce(i)=SummaryData.StdForce*1e6; % in uN   
    %     Touches{i}=(1:length(MeasuredVoltage))./SampleRate; %#ok<SAGROW>
    %     Cantilever{i}=CantileverName; %#ok<SAGROW>
end
figure(10)
plot(Peaks.')


%% Check statistical distribution of data
figure(11)
allFData=Peaks(1,:).';
for i=1:size(Peaks,1)
    allFData=[allFData; Peaks(i,:).']; 
%     normalityTest(i)=kstest(Peaks(i,:)); 
    lognormalTest(i)=lillietest(log(Peaks(i,:)),'Distr','norm'); %#ok<*AGROW>
end
% normalityTest %#ok<NOPRT>
lognormalTest %#ok<NOPRT>
qqplot(log(allFData)) % check for lognormal distribution
% histfit(allFData,50,'lognormal')
% [f,xi]=ksdensity(allFData);

% lognormal stats
mu=mean(log(allFData));
sigma=std(log(allFData));
% [M,V]=lognstat(mu,sigma);

lognlike([mu,sigma],allFData)
figure(12)
histfit(allFData,20,'lognormal')
hold all

medianForces=median(Peaks,2);
[~,I]=sort(medianForces);
plotPeaks=zeros(size(Peaks));
figure(13)
hold on
for i=1:size(Peaks,1)
    plotPeaks(i,:)=Peaks(I(i),:);
    plot(Peaks(I(i),i),'linestyle','none','marker','x')
end
figure(14)
% plot(1:13,plotPeaks,'linestyle','none','marker','o')
boxplot(plotPeaks.','whisker',9.5)
disp(Peaks)


%% Forces by volunteer
[MeanForce, I]=sort(MeanForce);
StdForce=StdForce(I);

axesLineWidths=2;
dataLineWidths=0.75;

% Create figure
figure1 = figure(figIndex);
set(gcf,'Units',            'inches',...
        'Position',         [0 2 3.5 3.5/1.6],...
        'PaperPositionMode','auto',...
        'PaperSize',        [3.5 3.5/1.6])

    
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
boxplot(plotPeaks.','whisker',9.5)


% Create line for worm touch threshold

line([0 15],[2 2],...
    'Color',        'r',...
    'DisplayName',  ' ',...%['Worm Response Saturation: ~2 ', '\mu',  'N'],...
    'LineWidth',    dataLineWidths)


[legh,~,~,~] = legend('Location',     'NorthWest');
% objh
oldPosition=get(legh,'Position'); %#ok<NASGU>
set(legh,'LineWidth',axesLineWidths,...
    'Interpreter',  'tex',...
    'Position',     [0.1528    0.7    0.2    0.2452],...%oldPosition+[0 0.05 -0.1 0],...
    'FontSize',     1)
legend(gca, 'boxoff')


% Create errorbar
errorbar(MeanForce,StdForce/sqrt(30),'MarkerSize',10,'MarkerFaceColor','none',...
    'MarkerEdgeColor',[0 0 0],...
    'Marker','none',...
    'LineStyle','none',...
    'LineWidth',dataLineWidths,...
    'Color',[0 0 0]);

set(gca,'XTickLabelMode',       'manual',...
    'XTickLabel',           [],...
    'XTick',                [],...%1 2 3 4 5 6 7 8 9 10 11 12 13 14],...
    'Box',                  'off',...
    'TickLength',           [0.025 0.025])

autoYLim=ylim
% ylim(axes1,[0 autoYLim(2)]);


[newX, newY]=MiriamAxes(gca,'xy');
set(newX,'XTick',[],'YScale','log');
set(newY,'YScale','log');
oldPosition=get(newY,'Position');
set(newY,'Position',[oldPosition(1) oldPosition(2) oldPosition(3) oldPosition(4)-.025]);
set(get(newX,'XLabel'),'Visible','off');
set(get(newY,'YLabel'),'Visible','off');

if strcmp(options.SaveFigures,'Yes')
    % saveas(gcf,'VForceVsubject.eps','epsc')
    % saveas(gcf,'/Users/adam/Documents/MATLAB/HairSwipe/Paper/SubjectForceFig','pdf')
end
figIndex=figIndex+1; %#ok<NASGU>


end
