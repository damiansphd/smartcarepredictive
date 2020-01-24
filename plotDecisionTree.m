function plotDecisionTree(mdl, pmHyperParamQS, fold, ntree, plotsubfolder, basefilename)

% plotDecisionTree - plots a decision tree graphically

filename = appendHyperParamToFileName(basefilename, pmHyperParamQS.HyperParamQS.LearnRate(end), ...
    pmHyperParamQS.HyperParamQS.NumTrees(end), pmHyperParamQS.HyperParamQS.MinLeafSize(end), ...
    pmHyperParamQS.HyperParamQS.MaxNumSplit(end));

filename = sprintf('%s-F%d-T%d', filename, fold, ntree);

before = findall(groot, 'Type', 'figure'); % Find all figures
view(mdl.Folds(fold).Model.Trained{ntree}, 'Mode', 'graph')
after = findall(groot,'Type','figure');
f = setdiff(after,before); % Get the figure handle of the tree viewer
f.Position = [100, 100, 2400, 1200];

basedir = setBaseDir();
savePlotInDir(f, filename, basedir, plotsubfolder);
%savePlotInDirAsSVG(f, baseplotname1, plotsubfolder);
close(f);

end

