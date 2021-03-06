function [modelcalibration] = calcModelCalibrationByFold(trcvfeatureindex, trcvpatientsplit, trcvlabels, modeldayres, ...
                                    basemodelresultsfile, plotsubfolder, lbdisplayname, labelidx)
                                
% calcModelCalibrationByFold - calculates (and plots) the model calibration
% by fold)

% set the number of bins to calibrate over
nbins = 10;
smalldatathresh = 30;

% calculate bin edges & midpoints
binedges = zeros(1, nbins + 1);
for n = 1:nbins
    binedges(n + 1) = n / nbins;
end
binmids = zeros(1, nbins);
for n = 2:nbins + 1
    binmids(n - 1) = (binedges(n) + binedges(n - 1))/ 2;
end

nfolds = size(modeldayres.Folds,2);
plotsdown = nfolds + 1;
plotsacross = 2;

name1 = sprintf('%s-%s%dModCalib', basemodelresultsfile, lbdisplayname, labelidx);
[f1, p1] = createFigureAndPanel(name1, 'Portrait', 'A4');
ax1 = gobjects(nfolds + 1,1);

fold = 0;
plotnbr = (2 * fold) + 1;
modelcalibration = calcModelCalibration(trcvlabels, modeldayres.Pred, binedges, nbins, fold);
ax1(plotnbr) = subplot(plotsdown, plotsacross, plotnbr, 'Parent', p1);
sdidx = (modelcalibration.NbrInBin(modelcalibration.Fold == fold) <= smalldatathresh);
plotModelCalibration(ax1(plotnbr), binmids, modelcalibration.Calibration(modelcalibration.Fold == fold), sdidx, [0.7, 0.7, 0.7], 'Blue', 'Red', 'Overall');
ax1(plotnbr + 1) = plottextModelCalibrationTable(p1, ax1(plotnbr), modelcalibration(modelcalibration.Fold == fold, :), fold, plotsacross, sdidx);

%for fold = 1:nfolds
%    plotnbr = (2 * fold) + 1;
%    cvidx = ismember(trcvfeatureindex.PatientNbr, trcvpatientsplit.PatientNbr(trcvpatientsplit.SplitNbr == fold));
%    tmpcalib = calcModelCalibration(trcvlabels(cvidx), modeldayres.Pred(cvidx), binedges, nbins, fold);
%    modelcalibration = [modelcalibration; tmpcalib];
%    ax1(plotnbr) = subplot(plotsdown, plotsacross, plotnbr, 'Parent', p1);
%    sdidx = (modelcalibration.NbrInBin(modelcalibration.Fold == fold) <= smalldatathresh);
%    plotModelCalibration(ax1(plotnbr), binmids, modelcalibration.Calibration(modelcalibration.Fold == fold), sdidx, [0.7, 0.7, 0.7], 'Blue', 'Red', sprintf('Fold %d', fold));
%    ax1(plotnbr + 1) = plottextModelCalibrationTable(p1, ax1(plotnbr), modelcalibration(modelcalibration.Fold == fold, :), fold, plotsacross, sdidx);
%end

basedir = setBaseDir();
savePlotInDir(f1, name1, basedir, plotsubfolder);
close(f1);
    
end

