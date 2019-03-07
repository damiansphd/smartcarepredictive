function plotModelWeights(pmModelRes, measures, nmeasures, pmTrCVPatientSplit, ...
    featureparamsrow, pmModelParamsRow, lbdisplayname, plotsubfolder, basemodelresultsfile)

% plotModelWeights - plots the model weights for all prediction labels
% for both given labels 


[featureduration, ~, monthfeat, demofeat, ...
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
    plotsdown = nfolds;
    
    name1 = sprintf('%s Feature Weights - %s Labels %d Day Prediction', basemodelresultsfile, lbdisplayname, n);
    [f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
    ax1 = gobjects(nfolds,1);
        
    for fold = 1:nfolds
        if ismember(pmModelParamsRow.Version(1), {'vPM1', 'vPM3', 'vPM4', 'vPM5'})
            intercept      = pmModelRes.pmNDayRes(n).Folds(fold).Model.Coefficients.Estimate(1);
            featureweights = pmModelRes.pmNDayRes(n).Folds(fold).Model.Coefficients.Estimate(2 : end);
        elseif ismember(pmModelParamsRow.Version(1), {'vPM2'})
            featureweights = pmModelRes.pmNDayRes(n).Folds(fold).Model.w;
        else
            fprintf('Unsupported model version\n');
            return;
        end
            
        ax1(fold) = subplot(plotsdown, plotsacross, fold, 'Parent',p1);
        % plot feature weights for a given prediction day (labelidx)
        bar(ax1(fold), (1:nnormfeatures), featureweights, 'FaceColor', 'blue');
        
        xl1 = [0 nnormfeatures];
        minval = 0; maxval = 0;
        minval = min(minval, min(featureweights));
        maxval = max(maxval, max(featureweights));
        yl1 = [minval maxval];
        ylim(ax1(fold), yl1);
        
        hold on;
        nextfeat = 0.5;
        [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        if nrawmeasures > 0
            mf =  nrawfeatures/nrawmeasures;
            for i = 1:nrawmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if nbucketmeasures > 0
            mf =  nbucketfeatures/nbucketmeasures;
            for i = 1:nbucketmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if nrangemeasures > 0
            mf =  nrangefeatures/nrangemeasures;
            for i = 1:nrangemeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if nvolmeasures > 0
            mf =  nvolfeatures/nvolmeasures;
            for i = 1:nvolmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if navgsegmeasures > 0
            mf =  navgsegfeatures/navgsegmeasures;
            for i = 1:navgsegmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if nvolsegmeasures > 0
            mf =  nvolsegfeatures/nvolsegmeasures;
            for i = 1:nvolsegmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if ncchangemeasures > 0
            mf =  ncchangefeatures/ncchangemeasures;
            for i = 1:ncchangemeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if npmeanmeasures > 0
            mf =  npmeanfeatures/npmeanmeasures;
            for i = 1:npmeanmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if npstdmeasures > 0
            mf =  npstdfeatures/npstdmeasures;
            for i = 1:npstdmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if nbuckpmeanmeasures > 0
            mf =  nbuckpmeanfeatures/nbuckpmeanmeasures;
            for i = 1:nbuckpmeanmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if nbuckpstdmeasures > 0
            mf =  nbuckpstdfeatures/nbuckpstdmeasures;
            for i = 1:nbuckpstdmeasures - 1
                nextfeat = nextfeat + mf;
                [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], ':', 1);
            end
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if monthfeat > 0
            mf =  ndatefeatures;
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        if demofeat > 1
            mf =  ndemofeatures;
            nextfeat = nextfeat + mf;
            [xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, [0.8, 0.8, 0.8], '-', 1);
        end
        
        hold off;
        
        set(gca,'fontsize',6);
        title(ax1(fold), sprintf('Fold %d (Intercept %.2f)', fold, intercept),'FontSize', 6);
        xlabel('Feature Window', 'FontSize', 6);
        ylabel('Feature Weights', 'FontSize', 6);
        
    end

    basedir = setBaseDir();
    savePlotInDir(f1, name1, basedir, plotsubfolder);
    close(f1);
end

end

