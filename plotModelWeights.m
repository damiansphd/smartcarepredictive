function plotModelWeights(pmIVModelRes, pmExModelRes, measures, nmeasures, ...
    pmFeatureParamsRow, plotsubfolder, basemodelresultsfile)

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

for n = 1:predictionduration
    %ivintercept      = pmIVModelRes.pmNDayRes(n).Model.Coefficients.Estimate(1);
    ivfeatureweights = pmIVModelRes.pmNDayRes(n).Model.Coefficients.Estimate(2 : (featureduration * nmeasures) + 1);
    %exintercept      = pmExModelRes.pmNDayRes(n).Model.Coefficients.Estimate(1);
    exfeatureweights = pmExModelRes.pmNDayRes(n).Model.Coefficients.Estimate(2 : (featureduration * nmeasures) + 1);
    
    minivval = 0; maxivval = 0; minexval = 0; maxexval = 0;
    minivval = min(minivval, min(ivfeatureweights));
    maxivval = max(maxivval, max(ivfeatureweights));
    minexval = min(minexval, min(exfeatureweights));
    maxexval = max(maxexval, max(exfeatureweights));
    yl1 = [min(minivval, minexval) max(maxivval, maxexval)];

    name1 = sprintf('%s Feature Weights - %d Day Prediction', basemodelresultsfile, n);
    [f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
    ax1 = gobjects(nmeasures,1);

    for m = 1:nmeasures
        ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
        % plot IV feature weights for a given prediction day (labelidx)
        line(ax1(m), (1:featureduration), ivfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)), ...
            'Color', 'red', 'LineStyle', ':', 'LineWidth', 0.5);
        line(ax1(m), (1:featureduration), smooth(ivfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)),5), ...
            'Color', 'red', 'LineStyle', '-', 'LineWidth', 0.5);
        line(ax1(m), (1:featureduration), exfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)), ...
            'Color', 'blue', 'LineStyle', ':', 'LineWidth', 0.5);
        line(ax1(m), (1:featureduration), smooth(exfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)),5), ...
            'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
        xlim(xl1);
        %yl1 = [min(min(ivfeatureweights(((m-1)*featureduration) + 1:(m * featureduration))), ...
        %    min(exfeatureweights(((m-1)*featureduration) + 1:(m * featureduration)))) ...
        %    max(max(ivfeatureweights(((m-1)*featureduration) + 1:(m * featureduration))), ...
        %    max(exfeatureweights(((m-1)*featureduration) + 1:(m * featureduration))))];
        ylim(yl1);
        set(gca,'fontsize',6);
        title(ax1(m), measures.DisplayName{m},'FontSize', 6);
        xlabel('Feature Window', 'FontSize', 6);
        ylabel('Feature Weights', 'FontSize', 6);
        lgd = legend(ax1(m), {'IV Raw', 'IV Smooth', 'Ex Raw', 'Ex Smooth'}, 'Location', 'southwest');
        lgd.NumColumns = 2;
        lgd.FontSize = 4;
        
    end

    basedir = setBaseDir();
    savePlotInDir(f1, name1, basedir, plotsubfolder);
    close(f1);
end

end

