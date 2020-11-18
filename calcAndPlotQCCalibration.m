function calcAndPlotQCCalibration(pmQCModelRes, labels, pmMissPattIndex, nqcfolds, basemodelresultsfile, plotsubfolder)

% calcAndPlotQCCalibration - calculates and plots the calibration curve for the quality
% classifier - overall and by fold

% set the number of bins to calibrate over
nbins = 10;
plotsperpage = 4;

% calculate bin edges & midpoints
binedges = zeros(1, nbins + 1);
for n = 1:nbins
    binedges(n + 1) = n / nbins;
end
binmids = zeros(1, nbins);
for n = 2:nbins + 1
    binmids(n - 1) = (binedges(n) + binedges(n - 1))/ 2;
end

name = sprintf('%s Calib', basemodelresultsfile);
[f, p] = createFigureAndPanel(name, 'Portrait', 'A4');
cplot = 1;

% first calculate overall calibration
fold = 0;
modelcalibration = calcModelCalibration(labels, pmQCModelRes.Pred, binedges, nbins, fold);
plotQCCalibration(p, modelcalibration, binmids, fold, plotsperpage, cplot, 'Overall');

% then do for each fold
for fold = 1:nqcfolds
    cplot = cplot + 1;
    fidx = pmMissPattIndex.QCFold == fold;
    modelcalibration = calcModelCalibration(labels(fidx), pmQCModelRes.Pred(fidx), binedges, nbins, fold);
    plotQCCalibration(p, modelcalibration, binmids, fold, plotsperpage, cplot, sprintf('Fold %d', fold));
end
            
basedir = setBaseDir();
savePlotInDir(f, name, basedir, plotsubfolder);
close(f); 

end

