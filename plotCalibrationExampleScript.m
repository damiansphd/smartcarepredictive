
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
color1 = [188/255 188/255, 229/255];
color2 = 'black';
color3 = [196/255, 159/255, 132/255];
color4 = [0.75 0.75 0.75];

rng(3);
xdata = 5:10:95;
for i = 1:size(xdata, 2)
    randval = ((rand - 0.5) * 30);
    fprintf('%.2f\n', randval)
    ydata(i) = xdata(i) + randval;
end

[f, p] = createFigureAndPanelForPaper('', widthinch, heightinch);
ax = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
line(ax, [0 100], [0 100], 'Color', color4, 'LineStyle', '-', 'LineWidth', 1);
line(ax, xdata, ydata, 'Color', color1, 'LineStyle', '-', 'LineWidth', 2, ...
    'Marker', 'o', 'MarkerSize', 5, 'MarkerEdgeColor', color2, 'MarkerFaceColor', color3);

ax.FontSize = 8;
ax.FontName = fontname;
ax.FontWeight = 'bold';
xlabel(ax, 'Bin Mid-points (%)', 'FontSize', 8);
ylabel(ax, 'Proportion of True Labels (%)', 'FontSize', 8);
xlim(ax, [0 100]);

% save plot
basedir = setBaseDir();
plottitle = sprintf('Thesis-ExampleCalibrationPlot');
plotsubfolder = 'Plots';
savePlotInDir(f, plottitle, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, plottitle, plotsubfolder);
close(f);
