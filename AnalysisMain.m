% Analyze Hair Touch Data
% Copyright Adam Nekimken, 2016

clear all
close all

options = AnalysisOptions;

ParseRawData(options);

ProcessData(options);

PlotData(options)

