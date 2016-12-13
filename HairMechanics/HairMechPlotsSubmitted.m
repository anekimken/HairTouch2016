% makes plots for hair mechanics from data that was already processed
% Adam Nekimken
% Started coding: 13 January 2016
% Cleaned up for publication: 12 December 2016

close all
clear all
savePlots='No' %#ok<NOPTS>
compileData='Yes' %#ok<NOPTS>

plotSize=[0.35 0.25 2.35 3/1.6-.5];
plotPos=[0 2 3 3/1.6];
paperDimension=[3 3/1.6];

% load one file for example plots
FileName='ALN_Bend1.txt';
PathName='/Users/adam/Documents/MATLAB/HairSwipe/HairMechanics/HM_12-3-15/';
fileID=fopen([PathName FileName]);
data=textscan(fileID,'%f %f %f','HeaderLines',9);

[sensitivity]=SensitivityCalc('AN-HS9A',965,10.05,.0589); % in um/V
CantileverStiffness=1.003; % for AN-HS9A
CantileverForce=data{3}.*sensitivity*CantileverStiffness;
deflection=data{2}./1e6-data{3}.*sensitivity; % in m  % note: if deflection of cantilever leads to positive signal, subtract here (and vice versa)
smoothedDeflection=smooth(deflection,21);


% example of deformation profile
figure('Units','inches',...
    'Position',plotPos,...
    'PaperPositionMode','auto',...
    'PaperSize',paperDimension)
plot(0:0.001:size(smoothedDeflection,1)/1000-.001, smoothedDeflection*1e6,'k','LineWidth',1)
ylimits=ylim;
ylim([0 ylimits(2)])
set(gca,'FontSize',10)
set(gca,'Box','off','Units','inches',...
    'ActivePositionProperty','Position',...
    'Position',plotSize,'FontSize',10,'FontName','Arial')
[newX,newY]=MiriamAxes(gca,'xy');
set(get(newX,'XLabel'),'Visible','off')
set(get(newY,'YLabel'),'Visible','off')


%example of Force v deflection plot with best fit line
figure('Units','inches',...
    'ActivePositionProperty','Position',...
    'Position',plotPos,...
    'PaperPositionMode','auto',...
    'PaperSize',paperDimension)
plot(deflection*1e6,CantileverForce*1e6,'k','DisplayName','Indentation Data','LineWidth',0.5)
ylimits=ylim;
xlimits=[0 60];
hold all
set(gca,'FontSize',10)

Fdfit=fit(deflection*1e6,CantileverForce*1e6,'poly1');
fitPlot=plot(Fdfit,'b');
set(fitPlot,'LineWidth',1.25)
ylim(ylimits)
xlim([0 xlimits(2)])
legend off
set(gca,'Box','off','Units','inches',...
    'ActivePositionProperty','Position',...
    'Position',plotSize,'FontSize',10,'FontName','Arial')
[newX,newY]=MiriamAxes(gca,'xy');
set(get(newX,'XLabel'),'Visible','off')
set(get(newY,'YLabel'),'Visible','off')

%% Stiffness vs. free length plot

%load data
load('HairLengths.mat');
daterTots=dir('*_ProcessedData.mat');
FreeLength=zeros(size(daterTots));
kPoints=cell(size(daterTots));
kAvg=zeros(size(daterTots));
fitData=zeros(size(daterTots));
index=1;


for i=1:size(daterTots,1)
    load(daterTots(i).name);
    for j=1:size(HairLengths,1)
        if strcmp(daterTots(i).name,HairLengths{j,1})
            FreeLength(i)=HairLengths{j,2}*1e-3;
        end
    end
    kPoints{i}=stiffness;
    kAvg(i)=mean(kPoints{i});
   
    for k=1:size(kPoints{i},1)
        fitData(index,1)=FreeLength(i)*1e3;
        fitData(index,2)=kPoints{i}(k);
        index=index+1;
    end
    
    if strcmp(compileData,'Yes')
        if exist('/Users/adam/Documents/MATLAB/HairTouch2016/HairMechanics/HairMechData.mat','file')
            load('/Users/adam/Documents/MATLAB/HairTouch2016/HairMechanics/HairMechData.mat')
        end
        
        CantileverForce=data{3}.*sensitivity*CantileverStiffness;
        deflection=data{2}./1e6-data{3}.*sensitivity;
        
        HairMechanicsDataByHair(i).('Force')=CantileverForce; %#ok<SAGROW>
        HairMechanicsDataByHair(i).('Deflection')=deflection; %#ok<SAGROW>
        HairMechanicsDataByHair(i).('CalculatedStiffness')=stiffness; %#ok<SAGROW>
        HairMechanicsDataByHair(i).('Length')=FreeLength(i); %#ok<SAGROW>
    end
    
    
end

% Fit cubic to data
inverseCubic=fittype('a/(x)^3');
options=fitoptions('Method','NonLinearLeastSquares');
Lkfit=fit(fitData(:,1),fitData(:,2),inverseCubic,options);


%make plot
figure('Units','inches',...
    'Position',plotPos,...
    'PaperPositionMode','auto',...
    'PaperSize',paperDimension)
set(gca,'FontSize',10,'FontName','Arial')
hold on
for i=1:size(daterTots,1)
    plot(FreeLength(i,1)*1e3, kPoints{i,1},'ko','MarkerSize',5,'LineWidth',.25)    
end

fitPlot=plot(Lkfit,'b');
legend off
set(fitPlot,'LineWidth',1.25)

ylimits=ylim;
ylim('auto')
% set(gca,'XScale','log')
% set(gca,'YScale','log')
xlimits=xlim;
xlim([4 xlimits(2)])
pause
set(gca,'FontSize',10)
set(gca,'Box','off','Units','inches',...
    'ActivePositionProperty','Position',...
    'Position',plotSize,'FontSize',10,'FontName','Arial')
[newX,newY]=MiriamAxes(gca,'xy');
set(newX,'FontSize',10,'FontName','Arial')
set(newY,'FontSize',10,'FontName','Arial')

set(get(newX,'XLabel'),'Visible','off')
set(get(newY,'YLabel'),'Visible','off')


%% Save plots
if strcmp(savePlots,'Yes')
    saveas(figure(1),'DeflectionTimePlot','pdf')
    saveas(figure(1),'DeflectionTimePlot.fig')
    saveas(figure(2),'ForceDistancePlot','pdf')
    saveas(figure(2),'ForceDistancePlot.fig')
    saveas(figure(3),'StiffnessVLengthPlot','pdf')
    saveas(figure(3),'StiffnessVLengthPlot.fig')
end


%% Save raw data
if strcmp(compileData,'Yes')
    save('/Users/adam/Documents/MATLAB/HairTouch2016/HairMechanics/HairMechData.mat','HairMechanicsDataByHair')
end
