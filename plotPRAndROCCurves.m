function plotPRAndROCCurves(pmModelRes, pmFeatureParamsRow, lbdisplayname, ...
    plotsubfolder, basemodelresultsfile)

% plotPRAndROCCurves - plots PR and ROC curves for the model results

predictionduration = size(pmModelRes.pmNDayRes, 2);

if predictionduration <= 3
    plotsacross = 1;
elseif predictionduration <= 6
    plotsacross = 2;
elseif predictionduration <= 12
    plotsacross = 3;
else
    plotsacross = 4;
end
plotsdown   = ceil(predictionduration/plotsacross);

name1 = sprintf('%s PR Curve %s Labels',  basemodelresultsfile, lbdisplayname);
name2 = sprintf('%s ROC Curve %s Labels', basemodelresultsfile, lbdisplayname);
[f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
[f2, p2] = createFigureAndPanel(name2, 'Portrait', 'A4');
ax1 = gobjects(predictionduration,1);
ax2 = gobjects(predictionduration,1);

yl1 = [0 1];

for n = 1:predictionduration
%for n = 5:5
    ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent',p1);
    line(ax1(n), pmModelRes.pmNDayRes(n).Recall, pmModelRes.pmNDayRes(n).Precision, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    ylim(ax1(n), yl1);
    set(gca,'fontsize',6);
    title(ax1(n), sprintf('PR Curve - %d Day Prediction', n),'FontSize', 6);
    xlabel(ax1(n), 'Recall', 'FontSize', 6);
    ylabel(ax1(n), 'Precision', 'FontSize', 6);
    text1 = sprintf('AUC %.2f', pmModelRes.pmNDayRes(n).PRAUC);
    legend(ax1(n), {text1}, 'Location', 'best', 'FontSize', 6);
    
    ax2(n) = subplot(plotsdown, plotsacross, n, 'Parent',p2);
    line(ax2(n), pmModelRes.pmNDayRes(n).FPR, pmModelRes.pmNDayRes(n).TPR, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    ylim(ax2(n), yl1);
    set(gca,'fontsize',6);
    title(ax2(n), sprintf('ROC Curve - %d Day Prediction', n),'FontSize', 6);
    xlabel(ax2(n), 'FPR', 'FontSize', 6);
    ylabel(ax2(n), 'TPR', 'FontSize', 6);
    text2 = sprintf('AUC %.2f', pmModelRes.pmNDayRes(n).ROCAUC);
    legend(ax2(n), {text2}, 'Location', 'best', 'FontSize', 6);
end

basedir = setBaseDir();
savePlotInDir(f1, name1, basedir, plotsubfolder);
savePlotInDir(f2, name2, basedir, plotsubfolder);
close(f1);
close(f2);

end

