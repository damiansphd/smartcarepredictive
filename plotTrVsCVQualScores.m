function plotTrVsCVQualScores(pmHyperParamQS, mdl, plotsubfolder, basefilename)

% plotTrVsCVQualScores - plots the various quality scores calculated on
% Training data and Cross Validation data. To help determine the optimal
% choce of hyper parameters

widthinch = 8.25;
heightinch = 11;

nfolds = size(mdl.Folds, 2);
qsarray = [{'AvgLoss'}        , {'min'} ; ...
           {'PRAUC'}          , {'max'} ; ...
           {'ROCAUC'}         , {'max'} ; ...
           {'Acc'}            , {'max'} ; ...
           {'AvgEPV'}         , {'max'} ; ...
           {'MaxNumNodes'}    , {'max'} ; ...
           {'MaxBranchNodes'} , {'max'} ];
       
nqs = size(qsarray, 1);
plotsacross = nfolds;
plotsdown = nqs;
pcount = 1;
color1 = 'red';
color2 = 'blue';

foldhptrqs = pmHyperParamQS.FoldHpTrQS;
foldhpcvqs = pmHyperParamQS.FoldHpCVQS;

[lr, validresponse] = selectFromArray('Learn Rate', foldhptrqs.LearnRate);
if ~validresponse
    return;
end
[nt, validresponse] = selectFromArray('Number of Trees', foldhptrqs.NumTrees);
if ~validresponse
    return;
end
[mls, validresponse] = selectFromArray('Min Leaf Size', foldhptrqs.MinLeafSize);
if ~validresponse
    return;
end
[fvs, validresponse] = selectFromArray('Fraction of Variables to Sample', foldhptrqs.FracVarsToSample);
if ~validresponse
    return;
end

temp = split(basefilename, 'lr');
filename = sprintf('%slr%.2f-nt%d-ml%d-ns%d-%dfv%.2f-TrVsCVQS', temp{1}, lr, nt, mls, ...
                    min(foldhptrqs.MaxNumSplit), max(foldhptrqs.MaxNumSplit), fvs);

[f, p] = createFigureAndPanelForPaper(filename, widthinch, heightinch);

for qs = 1:nqs
    
    trdataallfolds = foldhptrqs(foldhptrqs.LearnRate        == lr   & ...
                                foldhptrqs.NumTrees         == nt   & ...
                                foldhptrqs.MinLeafSize      == mls  & ...
                                foldhptrqs.FracVarsToSample == fvs, :);
                                
    cvdataallfolds = foldhpcvqs(foldhpcvqs.LearnRate        == lr   & ...
                                foldhpcvqs.NumTrees         == nt   & ...
                                foldhpcvqs.MinLeafSize      == mls  & ...
                                foldhpcvqs.FracVarsToSample == fvs, :);
                              
    ymin = min(min(trdataallfolds{:, qsarray{qs, 1}}), min(cvdataallfolds{:, qsarray{qs, 1}}));
    ymax = max(max(trdataallfolds{:, qsarray{qs, 1}}), max(cvdataallfolds{:, qsarray{qs, 1}}));
    
    if ymin == ymax
        if ymin == 0
            ymin = 0;
            ymax = 1;
        else
            ymin = ymin * 0.9;
            ymax = ymax * 1.1;
        end
    end
    
    for fold = 1:nfolds
        trdata = trdataallfolds(trdataallfolds.Fold == fold, :);
                          
        cvdata = cvdataallfolds(cvdataallfolds.Fold == fold, :);
        
        ax = subplot(plotsdown, plotsacross, pcount, 'Parent', p);
        xdata = trdata.MaxNumSplit;
        y1data = trdata{:, qsarray{qs, 1}};
        y2data = cvdata{:, qsarray{qs, 1}};
        %ymin = min(min(y1data), min(y2data));
        %ymax = max(max(y1data), max(y2data));
    
        semilogx(ax, xdata, y1data, 'Color', color1, 'LineStyle', '-', 'LineWidth', 2);
        hold on;
        semilogx(ax, xdata, y2data, 'Color', color2, 'LineStyle', '-', 'LineWidth', 2);
        hold off;
        ylim(ax, [ymin, ymax]);
        if ismember(qsarray(qs, 2), 'min')
            [~, idx1] = min(y1data);
            x1pt = xdata(idx1);
            [~, idx2] = min(y2data);
            x2pt = xdata(idx2);
        elseif ismember(qsarray(qs, 2), 'max')
            [~, idx1] = max(y1data);
            x1pt = xdata(idx1);
            [~, idx2] = max(y2data);
            x2pt = xdata(idx2);
        else
            fprintf('Unknown function\n');
            return;
        end
        line(ax, [x1pt, x1pt], [ymin, ymax], 'Color', color1, 'LineStyle', ':', 'LineWidth', 1);
        line(ax, [x2pt, x2pt], [ymin, ymax], 'Color', color2, 'LineStyle', ':', 'LineWidth', 1);
        % need to edit this for multiple trees
        ax.FontSize = 6;
        xlabel(ax, 'Max Splits');
        ylabel(ax, 'Score');
        title(ax, sprintf('%s-F%d (%.2f, %d)', qsarray{qs, 1}, fold, y2data(idx2), x2pt));
        pcount = pcount + 1;
    end
end

basedir = setBaseDir();
savePlotInDir(f, filename, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end

