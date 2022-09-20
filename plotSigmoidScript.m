
clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

plotsdown   = 1; 
plotsacross = 1;
thisplot = 1;
widthinch = 3.5;
heightinch = 2.5;
fontname = 'Arial';

xdata = -10:1:10;
ydata = sigmoid(xdata);

[f, p] = createFigureAndPanelForPaper('', widthinch, heightinch);
ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
line(ax, xdata, ydata, 'Color', 'blue', 'LineStyle', '-', 'LineWidth', 2);
ax.FontSize = 8;
ax.FontName = fontname;
ax.FontWeight = 'bold';
xlabel(ax, 'x', 'FontSize', 8);
ylabel(ax, 'sigmoid(x)', 'FontSize', 8);
xlim(ax, [-10 10]);

% save plot
basedir = setBaseDir();
plottitle = sprintf('Sigmoid Function Plot');
plotsubfolder = 'Plots';
savePlotInDir(f, plottitle, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, plottitle, plotsubfolder);
close(f);
