function plotModelWeights(pmModelRes, measures, nmeasures, ...
    pmFeatureParamsRow, pmModelParamsRow, lbdisplayname, plotsubfolder, basemodelresultsfile)

% plotModelWeights - plots the model weights for all prediction labels
% for both given labels 

featureduration  = pmFeatureParamsRow.featureduration;
predictionduration = size(pmModelRes.pmNDayRes, 2);

xl1 = [1 featureduration];

tempmeasures  = measures(measures.RawMeas == 1,:);
tempnmeasures = size(tempmeasures,1);

if tempnmeasures <= 4
    plotsacross = 1;
    plotsdown = tempnmeasures;
else
    plotsacross = 2;
    plotsdown = round(tempnmeasures/plotsacross);
end

for n = 1:predictionduration
    
    if isequal(pmModelParamsRow.Version{1}, 'vPM1')
        %ivintercept      = pmIVModelRes.pmNDayRes(n).Model.Coefficients.Estimate(1);
        featureweights = pmModelRes.pmNDayRes(n).Model.Coefficients.Estimate(2 : (featureduration * tempnmeasures) + 1);
    elseif isequal(pmModelParamsRow.Version{1}, 'vPM2')
        featureweights = pmModelRes.pmNDayRes(n).Model.w(1:(featureduration * tempnmeasures));
    else
        fprintf('Unknown model version\n');
        return;
    end
    
    minval = 0; maxval = 0;
    minval = min(minval, min(featureweights));
    maxval = max(maxval, max(featureweights));
    yl1 = [minval maxval];

    name1 = sprintf('%s Feature Weights - %s Labels %d Day Prediction', basemodelresultsfile, lbdisplayname, n);
    [f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
    ax1 = gobjects(tempnmeasures,1);
    
    for m = 1:tempnmeasures
        
        ax1(m) = subplot(plotsdown, plotsacross, m, 'Parent',p1);
        % plot feature weights for a given prediction day (labelidx)
        line(ax1(m), (1:featureduration), featureweights(((m-1)*featureduration) + 1:(m * featureduration)), ...
            'Color', 'blue', 'LineStyle', ':', 'LineWidth', 0.5);
        line(ax1(m), (1:featureduration), smooth(featureweights(((m-1)*featureduration) + 1:(m * featureduration)),5), ...
            'Color', 'blue', 'LineStyle', '-', 'LineWidth', 0.5);
        xlim(ax1(m), xl1);
        ylim(ax1(m), yl1);
        set(gca,'fontsize',6);
        title(ax1(m), tempmeasures.DisplayName{m},'FontSize', 6);
        xlabel('Feature Window', 'FontSize', 6);
        ylabel('Feature Weights', 'FontSize', 6);
        lgd = legend(ax1(m), {'Raw', 'Smooth'}, 'Location', 'southwest');
        lgd.NumColumns = 2;
        lgd.FontSize = 4;
        
    end

    basedir = setBaseDir();
    savePlotInDir(f1, name1, basedir, plotsubfolder);
    close(f1);
end

end

