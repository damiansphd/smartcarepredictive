function [pmPRAUC] = plotPRAndROCCurves(pmIVModelRes, pmExModelRes, pmIVLabels, pmExLabels, ...
        pmFeatureParamsRow, plotsubfolder, basemodelresultsfile)

% plotPRAndROCCurves - plots PR and ROC curves for the model results

predictionduration = pmFeatureParamsRow.predictionduration;

if predictionduration <= 4
    plotsacross = 1;
elseif predictionduration <= 10
    plotsacross = 2;
elseif predictionduration <= 20
    plotsacross = 3;
else
    plotsacross = 4;
end
plotsdown   = round(predictionduration/plotsacross);

pmPRAUC = table('Size',[predictionduration, 3], ...
    'VariableTypes', {'double', 'double', 'double'}, ...
    'VariableNames', {'PredDay', 'IV', 'ExStart'});

name1 = sprintf('%s PR Curve', basemodelresultsfile);
[f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
ax1 = gobjects(predictionduration,1);

for n = 1:predictionduration
%for n = 5:5
    nexamples = size(pmIVLabels,1);

    ivpred = pmIVModelRes.pmLabel(n).Pred;
    [~, ivsortidx] = sort(ivpred, 'descend');
    ivlabelsort = pmIVLabels(ivsortidx, n);
    nivtrue = sum(ivlabelsort==1);
    
    expred = pmExModelRes.pmLabel(n).Pred;
    [~, exsortidx] = sort(expred, 'descend');
    exlabelsort = pmExLabels(exsortidx, n);
    nextrue = sum(exlabelsort==1);
    
    ivprecision = zeros(nexamples, 1);
    ivrecall = zeros(nexamples, 1);
    exprecision = zeros(nexamples, 1);
    exrecall = zeros(nexamples, 1);
    
    for a = 1:nexamples
        ivprecision(a) = sum(ivlabelsort(1:a)==1) / a;
        ivrecall(a)    = sum(ivlabelsort(1:a)==1) / nivtrue;
        exprecision(a) = sum(exlabelsort(1:a)==1) / a;
        exrecall(a)    = sum(exlabelsort(1:a)==1) / nextrue;
    end
    
    pmPRAUC.PredDay(n) = n;
    pmPRAUC.IV(n)      = trapz(ivrecall, ivprecision);
    pmPRAUC.ExStart(n) = trapz(exrecall, exprecision);
    
    ax1(n) = subplot(plotsdown, plotsacross, n, 'Parent',p1);
    line(ax1(n), ivrecall, ivprecision, ...
        'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
    line(ax1(n), exrecall, exprecision, ...
        'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
    set(gca,'fontsize',6);
    title(sprintf('PR Curve - %d Day Prediction',n),'FontSize', 6);
    xlabel('Recall', 'FontSize', 6);
    ylabel('Precision', 'FontSize', 6);
    ivtext = sprintf('IV - AUC %.2f', pmPRAUC.IV(n));
    extext = sprintf('Ex Start - AUC %.2f', pmPRAUC.ExStart(n));
    legend({ivtext, extext'}, 'Location', 'northeast', 'FontSize', 6);
end

basedir = setBaseDir();
savePlotInDir(f1, name1, basedir, plotsubfolder);
close(f1);

end

