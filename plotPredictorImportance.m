function plotPredictorImportance(pmFeatureParamsRow, pmHyperParamQS, measures, mdl, plotsubfolder, basefilename)

% plotPredictorImportance - plots bar chart of predictor importance for
% each fold in the trained model. Only works for feature types Raw
% Measures, Volatility, Stable Mean

widthinch = 8.25;
heightinch = 11;
filename = appendHyperParamToFileName(basefilename, pmHyperParamQS.HyperParamQS.LearnRate(end), ...
    pmHyperParamQS.HyperParamQS.NumLearnCycles(end), pmHyperParamQS.HyperParamQS.MinLeafSize(end), ...
    pmHyperParamQS.HyperParamQS.MaxNumSplit(end));
filename = sprintf('%s-PImp', filename);

[f, p] = createFigureAndPanelForPaper(filename, widthinch, heightinch);

nfolds = size(mdl.Folds, 2);
plotsacross = 1;
plotsdown = nfolds;
featureduration = pmFeatureParamsRow.featureduration;
nrawfeat = featureduration;
nvolfeat = featureduration - 1;

for fold = 1:nfolds
    ax = subplot(plotsdown, plotsacross, fold, 'Parent', p);
    y = mdl.Folds(fold).Model.predictorImportance;
    ymax = max(y);
    x = 1:size(y, 2);
    bar(ax, x, y);
    ylim(ax, [0, ymax]);
    title(ax, sprintf('Fold %d', fold));
    xp = 0;
    for i = 1:sum(measures.RawMeas)
        xp = xp + nrawfeat;
        line(ax, [xp + 0.5, xp + 0.5], [0, ymax], 'Color', 'red', 'LineStyle', '-');
    end
    for i = 1:sum(measures.Volatility)
        xp = xp + nvolfeat;
        line(ax, [xp + 0.5, xp + 0.5], [0, ymax], 'Color', 'green', 'LineStyle', '-');
    end
end

basedir = setBaseDir();
savePlotInDir(f, filename, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end

