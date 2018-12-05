function plotSelectPRAndROCCurves(pmIVModelRes, pmExModelRes, ...
        selectdays, plotsubfolder, basemodelresultsfile)

% plotPRAndROCCurves - plots PR and ROC curves for the model results

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
plotsdown   = ceil((nplots * 2)/plotsacross);

name1 = sprintf('%s IV Label PR and ROC Curve', basemodelresultsfile);
name2 = sprintf('%s Ex Start Label PR and ROC ROC Curve', basemodelresultsfile);
[f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
[f2, p2] = createFigureAndPanel(name2, 'Portrait', 'A4');
ax1 = gobjects((nplots * 2),1);
ax2 = gobjects((nplots * 2),1);

for n = 1:nplots
    ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent',p1);
    line(ax1(n), pmIVModelRes.pmNDayRes(selectdays(n)).Recall, pmIVModelRes.pmNDayRes(selectdays(n)).Precision, ...
        'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
    title(ax1(n), sprintf('PR Curve - %d Day Prediction', selectdays(n)),'FontSize', 6);
    xlim(ax1(n), [0 1]);
    ylim(ax1(n), [0 1]);
    xlabel(ax1(n), 'Recall', 'FontSize', 6);
    ylabel(ax1(n), 'Precision', 'FontSize', 6);
    ivtext1 = sprintf('IV - AUC %.2f', pmIVModelRes.pmNDayRes(selectdays(n)).PRAUC);
    legend(ax1(n), {ivtext1}, 'Location', 'best', 'FontSize', 6);
    
    ax1(nplots + n) = subplot(plotsdown, plotsacross, nplots + n, 'Parent',p1);
    line(ax1(nplots + n), pmIVModelRes.pmNDayRes(selectdays(n)).FPR,    pmIVModelRes.pmNDayRes(selectdays(n)).TPR, ...
        'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
    title(ax1(nplots + n), sprintf('ROC Curve - %d Day Prediction', selectdays(n)),'FontSize', 6);
    xlim(ax1(nplots + n), [0 1]);
    ylim(ax1(nplots + n), [0 1]);
    xlabel(ax1(nplots + n), 'FPR', 'FontSize', 6);
    ylabel(ax1(nplots + n), 'TPR', 'FontSize', 6);
    ivtext2 = sprintf('IV - AUC %.2f', pmIVModelRes.pmNDayRes(n).ROCAUC);
    legend(ax1(nplots + n), {ivtext2}, 'Location', 'best', 'FontSize', 6);
    
    ax2(n) = subplot(plotsdown, plotsacross, n, 'Parent',p2);
    line(ax2(n), pmExModelRes.pmNDayRes(selectdays(n)).Recall, pmExModelRes.pmNDayRes(selectdays(n)).Precision, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    title(ax2(n), sprintf('PR Curve - %d Day Prediction', selectdays(n)),'FontSize', 6);
    xlim(ax2(n), [0 1]);
    ylim(ax2(n), [0 1]);
    xlabel(ax2(n), 'Recall', 'FontSize', 6);
    ylabel(ax2(n), 'Precision', 'FontSize', 6);
    extext1 = sprintf('Ex Start - AUC %.2f', pmExModelRes.pmNDayRes(selectdays(n)).PRAUC);
    legend(ax2(n), {extext1}, 'Location', 'best', 'FontSize', 6);
    
    ax2(nplots + n) = subplot(plotsdown, plotsacross, nplots + n, 'Parent',p2);
    line(ax2(nplots + n), pmExModelRes.pmNDayRes(selectdays(n)).FPR,    pmExModelRes.pmNDayRes(selectdays(n)).TPR, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    title(ax2(nplots + n), sprintf('ROC Curve - %d Day Prediction', selectdays(n)),'FontSize', 6);
    xlim(ax2(nplots + n), [0 1]);
    ylim(ax2(nplots + n), [0 1]);
    xlabel(ax2(nplots + n), 'FPR', 'FontSize', 6);
    ylabel(ax2(nplots + n), 'TPR', 'FontSize', 6);
    extext2 = sprintf('Ex Start - AUC %.2f', pmExModelRes.pmNDayRes(selectdays(n)).ROCAUC);
    legend(ax2(nplots + n), {extext2}, 'Location', 'best', 'FontSize', 6);
    
end

basedir = setBaseDir();
savePlotInDir(f1, name1, basedir, plotsubfolder);
savePlotInDir(f2, name2, basedir, plotsubfolder);
close(f1);
close(f2);

end

