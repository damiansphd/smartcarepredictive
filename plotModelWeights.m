function plotModelWeights(pmModelRes, pmTrCVNormFeatures, measures, nmeasures, pmTrCVPatientSplit, ...
    featureparamsrow, pmModelParamsRow, lbdisplayname, plotsubfolder, basemodelresultsfile)

% plotModelWeights - plots the model weights for all prediction labels
% for both given labels 

lcolor = [0.8, 0.8, 0.8];

[featureduration, ~, datefeat, demofeat, ...
 nbuckets, navgseg, nvolseg, nbuckpmeas, nrawmeasures, nbucketmeasures, nrangemeasures, ...
 nvolmeasures, navgsegmeasures, nvolsegmeasures, ncchangemeasures, ...
 npmeanmeasures, npstdmeasures, nbuckpmeanmeasures, nbuckpstdmeasures, ...
 nrawfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
 nvolsegfeatures, ncchangefeatures, npmeanfeatures, npstdfeatures, ...
 nbuckpmeanfeatures, nbuckpstdfeatures, ndatefeatures, ndemofeatures, ...
 nfeatures, nnormfeatures] = setNumMeasAndFeatures(featureparamsrow, measures, nmeasures);

predictionduration = size(pmModelRes.pmNDayRes,2);

for n = 1:predictionduration
    
    nfolds = size(pmModelRes.pmNDayRes(n).Folds,2);

    plotsacross = 1;
    plotsdown = nfolds + 2;
    
    name1 = sprintf('%s-%s-%dDFWght', basemodelresultsfile, lbdisplayname, n);
    [f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
    ax1 = gobjects(plotsacross * plotsdown,1);
    
    fwarray = zeros(nnormfeatures + 1, nfolds);
    for fold = 1:nfolds
        if ismember(pmModelParamsRow.ModelVer(1), {'vPM1', 'vPM3', 'vPM4', 'vPM5'})
            fwarray(:, fold) = pmModelRes.pmNDayRes(n).Folds(fold).Model.Coefficients.Estimate;
        elseif ismember(pmModelParamsRow.ModelVer(1), {'vPM2'})
            fwarray(:, fold) = pmModelRes.pmNDayRes(n).Folds(fold).Model.w;
        else
            fprintf('Unsupported model version\n');
            return;
        end    
    end
    minval = 0; maxval = 0;
    minval = min(minval, min(min(fwarray(2:end, :))));
    maxval = max(maxval, max(max(fwarray(2:end, :))));
    yl1 = [minval maxval];
    
    for fold = 1:nfolds
        if ismember(pmModelParamsRow.ModelVer(1), {'vPM1', 'vPM3', 'vPM4', 'vPM5'})
            intercept      = fwarray(1, fold);
            featureweights = fwarray(2:end, fold);
        elseif ismember(pmModelParamsRow.ModelVer(1), {'vPM2'})
            featureweights = fwarray(1:end - 1, fold);
            intercept      = fwarray(end, fold);
        else
            fprintf('Unsupported model version\n');
            return;
        end
            
        ax1(fold) = subplot(plotsdown, plotsacross, fold, 'Parent',p1);
        
        % plot feature weights for a given prediction day (labelidx)
        bar(ax1(fold), (1:nnormfeatures), featureweights, 0.75, 'FaceColor', 'blue', 'EdgeColor', 'black');
        
        xl1 = [0 nnormfeatures];
        ylim(ax1(fold), yl1);
        
        hold on;
        nextfeat = 0.5;
        [xl1, yl1, nextfeat] = plotFeatureDividers(ax1(fold), featureparamsrow, measures, nmeasures, xl1, yl1, nextfeat, lcolor);
        hold off;
        
        set(gca,'fontsize',6);
        title(ax1(fold), sprintf('Fold %d (Intercept %.2f)', fold, intercept),'FontSize', 6);
        xlabel('Features', 'FontSize', 6);
        ylabel('Feature Weights', 'FontSize', 6);  
    end
    
    % plot std deviation of features
    fold = fold + 1;
    featurestd = std(pmTrCVNormFeatures,1);
    ax1(fold) = subplot(plotsdown, plotsacross, fold, 'Parent',p1);
    bar(ax1(fold), (1:nnormfeatures), featurestd, .75, 'FaceColor', 'green', 'EdgeColor', 'black');
    xl1 = [0 nnormfeatures];
    minval = 0; maxval = 0;
    minval = min(minval, min(featurestd));
    maxval = max(maxval, max(featurestd));
    yl1 = [minval maxval * 1.1];
    ylim(ax1(fold), yl1);
    
    hold on;
    nextfeat = 0.5;
    [xl1, yl1, nextfeat] = plotFeatureDividers(ax1(fold), featureparamsrow, measures, nmeasures, xl1, yl1, nextfeat, lcolor);
    hold off;
    set(gca,'fontsize',6);
    title(ax1(fold), 'Feature Std Deviation','FontSize', 6);
    xlabel('Features', 'FontSize', 6);
    ylabel('Feature Std Dev', 'FontSize', 6);  
    
    % plot mean of features
    fold = fold + 1;
    featuremean = mean(pmTrCVNormFeatures,1);
    ax1(fold) = subplot(plotsdown, plotsacross, fold, 'Parent',p1);
    bar(ax1(fold), (1:nnormfeatures), featuremean, .75, 'FaceColor', 'green', 'EdgeColor', 'black');
    xl1 = [0 nnormfeatures];
    minval = 0; maxval = 0;
    minval = min(minval, min(featuremean));
    maxval = max(maxval, max(featuremean));
    yl1 = [minval maxval * 1.1];
    ylim(ax1(fold), yl1);
    
    hold on;
    nextfeat = 0.5;
    [xl1, yl1, nextfeat] = plotFeatureDividers(ax1(fold), featureparamsrow, measures, nmeasures, xl1, yl1, nextfeat, lcolor);
    hold off;
    set(gca,'fontsize',6);
    title(ax1(fold), 'Feature Mean','FontSize', 6);
    xlabel('Features', 'FontSize', 6);
    ylabel('Feature Mean', 'FontSize', 6);  
    
    basedir = setBaseDir();
    savePlotInDir(f1, name1, basedir, plotsubfolder);
    close(f1);
end

end

