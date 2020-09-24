clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

% logic to load in results for a given feature&label version, label method and raw measures combination
[fv1, validresponse] = selectFeatVer();
if validresponse == 0
    return;
end
[lb1, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
[rm1, validresponse] = selectRawMeasComb();
if validresponse == 0
    return;
end
[basempresultsfile] = selectMPResultsFile(fv1, lb1, rm1);
mpresultsfile = sprintf('%s.mat', basempresultsfile);
basempresultsfile = strrep(basempresultsfile, ' MPRes', '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading missingness pattern results data for %s\n', mpresultsfile);
load(fullfile(basedir, subfolder, mpresultsfile), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmBaselineQS', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams');
toc
fprintf('\n');

% 'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 

widthinch = 8.25;
heightinch = 7.5;
name = '';
plotsacross = 2;
plotsdown = 3;
thisplot = 1;
labelfontsize = 8;

baseplotname1 = sprintf('%s-QS', basempresultsfile);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

xdata = 100 * sum(pmMissPattArray, 2) / size(pmMissPattArray, 2);

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);


ydata = pmMissPattQS.AvgEPV;
scatter(ax1, xdata, ydata, 20, 'b', 'o', 'filled');
set(gca,'fontsize',labelfontsize);
title('AvgEPV','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('Avg EPV', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmMissPattQS.PRAUC;
scatter(ax1, xdata, ydata, 20, 'b', 'o', 'filled');
set(gca,'fontsize',labelfontsize);
title('PRAUC','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('PRAUC', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmMissPattQS.ROCAUC;
scatter(ax1, xdata, ydata, 20, 'b', 'o', 'filled');
set(gca,'fontsize',labelfontsize);
title('ROCAUC','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('ROCAUC', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmMissPattQS.Acc;
scatter(ax1, xdata, ydata, 20, 'b', 'o', 'filled');
set(gca,'fontsize',labelfontsize);
title('Acc','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('Acc', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmMissPattQS.PosAcc;
scatter(ax1, xdata, ydata, 20, 'b', 'o', 'filled');
set(gca,'fontsize',labelfontsize);
title('PosAcc','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('PosAcc', 'FontSize', labelfontsize);


plotsubfolder = sprintf('Plots/MissPatQS');
mkdir(fullfile(basedir, plotsubfolder));

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
close(f);



