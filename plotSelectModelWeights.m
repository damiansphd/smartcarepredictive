function plotSelectModelWeights(pmIVModelRes, pmExModelRes, measures, nmeasures, ...
    pmFeatureParamsRow, selectdays, plotsubfolder, basemodelresultsfile)

% plotModelWeights - plots the model weights for all prediction labels
% for both the IV (red) and Ex_Start (blue) labels. 


featureduration  = pmFeatureParamsRow.featureduration;
predictionduration = pmFeatureParamsRow.predictionduration;

xl1 = [1 featureduration];

if nmeasures <= 4
    plotsacross = 1;
    plotsdown = nmeasures;
else
    plotsacross = 2;
    plotsdown = round(nmeasures/plotsacross);
end

for n = 1:size(selectdays,2)
    %ivintercept      = pmIVModelRes.pmNDayRes(n).Model.Coefficients.Estimate(1);
    ivfeatureweights = pmIVModelRes.pmNDayRes(selectdays(n)).Model.Coefficients.Estimate(2 : (featureduration * nmeasures) + 1);
    %exintercept      = pmExModelRes.pmNDayRes(n).Model.Coefficients.Estimate(1);
    exfeatureweights = pmExModelRes.pmNDayRes(selectdays(n)).Model.Coefficients.Estimate(2 : (featureduration * nmeasures) + 1);
    
    minivval = 0; maxivval = 0; minexval = 0; maxexval = 0;
    minivval = min(minivval, min(ivfeatureweights));
    maxivval = max(maxivval, max(ivfeatureweights));
    minexval = min(minexval, min(exfeatureweights));
    maxexval = max(maxexval, max(exfeatureweights));
    yl1 = [min(minivval, minexval) max(maxivval, maxexval)];

    name1 = sprintf('%s IV Feature Weights - %d Day Prediction', basemodelresultsfile, selectdays(n));
    name2 = sprintf('%s Ex Start Feature Weights - %d Day Prediction', basemodelresultsfile, selectdays(n));
    [f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
    [f2, p2] = createFigureAndPanel(name2, 'Portrait', 'A4');
    ax1 = gobjects(nmeasures,1);
    ax2 = gobjects(nmeasures,1);

    for m = 1:nmeasures
        ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
        % plot IV feature weights for a given prediction day (labelidx)
        line(ax1(m), (1:featureduration), ivfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)), ...
            'Color', 'red', 'LineStyle', ':', 'LineWidth', 0.5);
        line(ax1(m), (1:featureduration), smooth(ivfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)),5), ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
        xlim(ax1(m), xl1);
        ylim(ax1(m), yl1);
        %set(gca,'fontsize',6);
        title(ax1(m), measures.DisplayName{m},'FontSize', 6);
        xlabel(ax1(m), 'Feature Window', 'FontSize', 6);
        ylabel(ax1(m), 'Feature Weights', 'FontSize', 6);
        lgd = legend(ax1(m), {'IV Raw', 'IV Smooth'}, 'Location', 'southwest');
        lgd.FontSize = 4;
        
        ax2(m) = subplot(plotsdown, plotsacross, m, 'Parent',p2);
        % plot IV feature weights for a given prediction day (labelidx)
        line(ax2(m), (1:featureduration), exfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)), ...
            'Color', 'blue', 'LineStyle', ':', 'LineWidth', 0.5);
        line(ax2(m), (1:featureduration), smooth(exfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)),5), ...
            'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
        xlim(ax2(m), xl1);
        ylim(ax2(m), yl1);
        %set(gca,'fontsize',6);
        title(ax2(m), measures.DisplayName{m},'FontSize', 6);
        xlabel(ax2(m), 'Feature Window', 'FontSize', 6);
        ylabel(ax2(m), 'Feature Weights', 'FontSize', 6);
        lgd = legend(ax2(m), {'Ex Raw', 'Ex Smooth'}, 'Location', 'southwest');
        lgd.FontSize = 4;
        
    end

    basedir = setBaseDir();
    savePlotInDir(f1, name1, basedir, plotsubfolder);
    savePlotInDir(f2, name2, basedir, plotsubfolder);
    close(f1);
    close(f2);
end

end

