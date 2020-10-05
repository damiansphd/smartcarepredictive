function plotMissingnessQSFcn(pmMSModelRes, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, thresh, basemsresultsfile)

% plotMissingnessQSFcn - plots the quality scores vs the %age of missing
% data and also colour by correct vs incorrect result by the missingess
% classifier

widthinch = 8.25;
heightinch = 7.5;
name = '';
plotsacross = 2;
plotsdown = 3;
thisplot = 1;
labelfontsize = 8;

truepred = pmMSModelRes.Pred >= thresh;

correctpred = ~xor(truepred, trcvlabels);

baseplotname1 = sprintf('%s-QSC', basemsresultsfile);

[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

xdata = 100 * sum(pmTrCVMPArray, 2) / size(pmTrCVMPArray, 2);

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);

ydata = pmTrCVMPQS.AvgEPV;
hold on;
scatter(ax1, xdata(correctpred), ydata(correctpred), 20, 'b', 'o', 'filled');
scatter(ax1, xdata(~correctpred), ydata(~correctpred), 20, 'r', 'o', 'filled');
hold off;
set(gca,'fontsize',labelfontsize);
title('AvgEPV','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('Avg EPV', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmTrCVMPQS.PRAUC;
hold on;
scatter(ax1, xdata(correctpred), ydata(correctpred), 20, 'b', 'o', 'filled');
scatter(ax1, xdata(~correctpred), ydata(~correctpred), 20, 'r', 'o', 'filled');
hold off;
set(gca,'fontsize',labelfontsize);
title('PRAUC','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('PRAUC', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmTrCVMPQS.ROCAUC;
hold on;
scatter(ax1, xdata(correctpred), ydata(correctpred), 20, 'b', 'o', 'filled');
scatter(ax1, xdata(~correctpred), ydata(~correctpred), 20, 'r', 'o', 'filled');
hold off;
set(gca,'fontsize',labelfontsize);
title('ROCAUC','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('ROCAUC', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmTrCVMPQS.Acc;
hold on;
scatter(ax1, xdata(correctpred), ydata(correctpred), 20, 'b', 'o', 'filled');
scatter(ax1, xdata(~correctpred), ydata(~correctpred), 20, 'r', 'o', 'filled');
hold off;
set(gca,'fontsize',labelfontsize);
title('Acc','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('Acc', 'FontSize', labelfontsize);

thisplot = thisplot + 1;

ax1 = subplot(plotsdown, plotsacross, thisplot, 'Parent', p);
ydata = pmTrCVMPQS.PosAcc;
hold on;
scatter(ax1, xdata(correctpred), ydata(correctpred), 20, 'b', 'o', 'filled');
scatter(ax1, xdata(~correctpred), ydata(~correctpred), 20, 'r', 'o', 'filled');
hold off;
set(gca,'fontsize',labelfontsize);
title('PosAcc','FontSize', labelfontsize);
xlabel('Percent Missing Points', 'FontSize', labelfontsize);
ylabel('PosAcc', 'FontSize', labelfontsize);


basedir = setBaseDir();
plotsubfolder = sprintf('Plots/MissPatQS');
mkdir(fullfile(basedir, plotsubfolder));

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
close(f);

end

