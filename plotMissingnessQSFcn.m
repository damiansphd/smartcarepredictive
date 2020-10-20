function plotMissingnessQSFcn(pmMSModelRes, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, pmBaselineQS, qsthreshold, thresh, basemsresultsfile)

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
qsarray = {'AvgEPV', 'PRAUC', 'ROCAUC', 'Acc', 'PosAcc'};

truepred = pmMSModelRes.Pred >= thresh;
xdata = 100 * sum(pmTrCVMPArray, 2) / size(pmTrCVMPArray, 2);

baseplotname1 = sprintf('%s-QSC', basemsresultsfile);
[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);

for i = 1:size(qsarray, 2)
    ax1 = subplot(plotsdown, plotsacross, i, 'Parent', p);
    qsmeasure = qsarray{i};
    [baselineqsthresh] = calcQCthresh(table2array(pmBaselineQS(1, {qsmeasure})), qsthreshold);
    ydata = table2array(pmTrCVMPQS(:, {qsmeasure}));
    hold on;
    scatter(ax1, xdata(truepred), ydata(truepred), 20, 'b', 'o', 'filled');
    scatter(ax1, xdata(~truepred), ydata(~truepred), 20, 'r', 'o', 'filled');
    line(ax1, [0 100], [baselineqsthresh baselineqsthresh], ...
        'Color', 'black', ...
        'LineStyle', '-', ...
        'LineWidth', 1, ...
        'Marker', 'none');
    hold off;
    set(gca,'fontsize',labelfontsize);
    title(qsmeasure,'FontSize', labelfontsize);
    xlabel('Percent Missing Points', 'FontSize', labelfontsize);
    ylabel(qsmeasure, 'FontSize', labelfontsize);
end 

basedir = setBaseDir();
plotsubfolder = sprintf('Plots/MissPatQS');
mkdir(fullfile(basedir, plotsubfolder));

basedir = setBaseDir();
savePlotInDir(f, baseplotname1, basedir, plotsubfolder);
close(f);

end

