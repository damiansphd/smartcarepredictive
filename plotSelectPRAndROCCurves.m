function plotSelectPRAndROCCurves(pmModelRes, selectdays, lbdisplayname, ...
    plotsubfolder, basemodelresultsfile)

% plotSelectPRAndROCCurves - plots PR and ROC curves for the selected
% prediction days

nplots = size(selectdays,2);

if (nplots * 2) <= 3
    plotsacross = 1;
elseif (nplots * 2) <= 6
    plotsacross = 2;
elseif (nplots * 2) <= 12
    plotsacross = 4;
else
    plotsacross = 6;
end
plotsdown = ceil((nplots * 2)/plotsacross);

name1 = sprintf('%s-%s-PRROC', basemodelresultsfile, lbdisplayname);
[f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
ax1 = gobjects((nplots * 2),1);

for n = 1:nplots
    
    [pmRandomRes] = generateRandomPRAndROCResults(pmModelRes.pmNDayRes(n).LabelSort);
    
    ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent',p1);
    line(ax1(n), pmModelRes.pmNDayRes(selectdays(n)).Recall, pmModelRes.pmNDayRes(selectdays(n)).Precision, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    line(ax1(n), pmRandomRes.Recall, pmRandomRes.Precision, ...
        'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
    title(ax1(n), sprintf('PR Curve - %d Day Prediction', selectdays(n)),'FontSize', 6);
    xlim(ax1(n), [0 1]);
    ylim(ax1(n), [0 1]);
    xlabel(ax1(n), 'Recall', 'FontSize', 6);
    ylabel(ax1(n), 'Precision', 'FontSize', 6);
    prtext1 = sprintf('%d Day Pred - AUC %.2f', n, pmModelRes.pmNDayRes(n).PRAUC);
    prtext2 = sprintf('Random Pred - AUC %.2f', pmRandomRes.PRAUC);
    legend(ax1(n), {prtext1, prtext2}, 'Location', 'best', 'FontSize', 6);
    
    ax1(nplots + n) = subplot(plotsdown, plotsacross, nplots + n, 'Parent',p1);
    line(ax1(nplots + n), pmModelRes.pmNDayRes(selectdays(n)).FPR,    pmModelRes.pmNDayRes(selectdays(n)).TPR, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    line(ax1(nplots + n), pmRandomRes.FPR, pmRandomRes.FPR, ...
        'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
    title(ax1(nplots + n), sprintf('ROC Curve - %d Day Prediction', selectdays(n)),'FontSize', 6);
    xlim(ax1(nplots + n), [0 1]);
    ylim(ax1(nplots + n), [0 1]);
    xlabel(ax1(nplots + n), 'FPR', 'FontSize', 6);
    ylabel(ax1(nplots + n), 'TPR', 'FontSize', 6);
    roctext1 = sprintf('%d Day Pred - AUC %.2f', n, pmModelRes.pmNDayRes(n).ROCAUC);
    roctext2 = sprintf('Random Pred - AUC %.2f', pmRandomRes.ROCAUC);
    legend(ax1(nplots + n), {roctext1, roctext2}, 'Location', 'best', 'FontSize', 6);
    
end

basedir = setBaseDir();
savePlotInDir(f1, name1, basedir, plotsubfolder);
close(f1);

end

