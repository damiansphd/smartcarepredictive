function plotQCModelWeights(pmQCModelRes, pmMissPattArray, ...
    datawin, modelver, nqcfolds, plotsubfolder, basemodelresultsfile)

% plotQCModelWeights - plots the model weights for the quality classifier

if ~ismember(modelver, {'vPM1'})
    fprintf('The model weights plot is only relevant for the linear model\n');
    return
end

nnormfeatures = size(pmMissPattArray, 2);

axisfontsize = 10;
widthinch = 8.25;
heightinch = 6;
name = '';
lcolor = [0.8, 0.8, 0.8];

plotsacross = 1;
plotsdown = max(nqcfolds,2);

name1 = sprintf('%s-QCWght', basemodelresultsfile);
[f, p] = createFigureAndPanelForPaper(name, widthinch, heightinch);
ax1 = gobjects(plotsacross * plotsdown,1);

fwarray = zeros(nnormfeatures + 1, nqcfolds);
for fold = 1:nqcfolds
    fwarray(:, fold) = pmQCModelRes.Folds(fold).Model.Coefficients.Estimate;    
end

minval = 0; maxval = 0;
minval = min(minval, min(min(fwarray(2:end, :))));
maxval = max(maxval, max(max(fwarray(2:end, :))));
yl1 = [minval maxval];

for fold = 1:nqcfolds
    if ismember(modelver, {'vPM1'})
        intercept      = fwarray(1, fold);
        featureweights = fwarray(2:end, fold);
    end

    ax1(fold) = subplot(plotsdown, plotsacross, fold, 'Parent',p);

    % plot feature weights for a given prediction day (labelidx)
    bar(ax1(fold), (1:nnormfeatures), featureweights, 0.75, 'FaceColor', 'blue', 'EdgeColor', 'black');

    xl1 = [0.5 nnormfeatures + 0.5];
    ylim(ax1(fold), yl1);

    hold on;
    nmsmeasures = nnormfeatures/datawin;
    for i = 1:nmsmeasures - 1
        %nextfeat = nextfeat + datawin;
        %[xl1, yl1] = plotVerticalLine(ax1(fold), nextfeat, xl1, yl1, lcolor, '-', 1);
        [xl1, yl1] = plotVerticalLine(ax1(fold), 0.5 + (i * datawin), xl1, yl1, lcolor, '-', 1);
    end

    hold off;

    set(gca,'fontsize', axisfontsize);
    title(ax1(fold), sprintf('Fold %d (Intercept %.2f)', fold, intercept),'FontSize', axisfontsize);
    xlabel('Features', 'FontSize', axisfontsize);
    ylabel('Feature Weights', 'FontSize', axisfontsize);  
end

basedir = setBaseDir();
savePlotInDir(f, name1, basedir, plotsubfolder);
close(f);

end

