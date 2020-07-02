clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);


% logic to load in results for a given feature&label version, label method and raw measures combination
[fv1, validresponse] = selectFeatVer();
if validresponse == 0
    return;
end
[lb1, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
[rm1, validresponse] = selectRawMeasComb();
if validresponse == 0
    return;
end

[basemodelresultsfile] = selectModelResultsFile(fv1, lb1, rm1);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, ' ModelResults', '');

[ntiles, validresponse] = selectFromArray('Number of NTiles', [2; 3; 4; 5; 6]);
if ~validresponse
    return;
end

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
            'pmTrCVFeatureIndex', 'pmTrCVNormFeatures', ...
            'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels', 'pmTrCVExABLabels', 'pmTrCVExABxElLabels', ...
            'pmTrCVPatientSplit', 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

if pmOtherRunParams.runtype ~= 1
    fprintf('QS by Completeness only runs on Train/CV results\n');
    return;
end

featureparamsfile = generateFileNameFromFullFeatureParams(pmFeatureParamsRow);
featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsmatfile), 'pmPatients', 'pmAntibiotics', 'pmAMPred', ...
            'pmRawDatacube', 'pmInterpDatacube', 'pmInterpVolcube', 'mvolstats', ...
            'pmMucube', 'pmSigmacube', 'pmMuNormcube', 'pmSigmaNormcube', ...
            'pmBuckMuNormcube', 'pmBuckSigmaNormcube', 'muntilepoints', 'sigmantilepoints', ...
            'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures');
        
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

labelidx = min(size(pmModelRes.pmNDayRes, 2), 5);

[labels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);

featdur  = pmFeatureParamsRow.featureduration;
normwind = pmFeatureParamsRow.normwindow;

% first calculate data completeness for all TrCV examples
ntrcvexamples = size(pmTrCVFeatureIndex, 1);
pmTrCVFeatureIndex.FDDataComp(:) = 0;
for i = 1:ntrcvexamples
    pnbr       = pmTrCVFeatureIndex.PatientNbr(i);
    rundate    = pmTrCVFeatureIndex.CalcDatedn(i);
    mmidx      = logical(measures.RawMeas);
    fdactpts   = sum(sum(~isnan(pmRawDatacube(pnbr, rundate - featdur + 1:rundate, mmidx))));
    fdmaxpts   = featdur * sum(mmidx);
    pmTrCVFeatureIndex.FDDataComp(i)   = 100 * fdactpts   / fdmaxpts;
end

% next get sort indexes by completeness descending
[~, fdsortidx]   = sortrows(pmTrCVFeatureIndex, {'FDDataComp',   'PatientNbr', 'CalcDatedn'}, 'descend');

fddatacompQS = table('Size',[ntiles, 10], ...
                'VariableTypes', {'double', 'double',  'double', 'double',   'double', 'double', 'double', 'double', 'double', 'double'}, ...
                'VariableNames', {'NTile',  'FromIdx', 'ToIdx',  'DCFrom', 'DCTo', 'PRAUC',  'ROCAUC', 'Acc',    'PosAcc', 'NegAcc'});

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

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);
if ~exist(fullfile(basedir, plotsubfolder), 'dir')
    mkdir(fullfile(basedir, plotsubfolder));
end

colours = [ 247, 150,  70; ...
            155, 187,  89; ...
             79, 129, 189; ...
            196, 158, 108; ...
            199,  21, 108; ...
            126,  47, 142];
colours = colours ./ 255;
            

plotsacross1 = 2;
plotsdown1 = 4;
baseoutputfilename1 = sprintf('%s CalibByDataCompNT%d', ...
                    basemodelresultsfile, ntiles);
plotname1 = sprintf('%s', baseoutputfilename1);
[f1, p1] = createFigureAndPanel(plotname1, 'Portrait', 'A4');
            
for i = 1:ntiles
    frompt = 1 + floor((i - 1) * (ntrcvexamples/ntiles));
    topt   = floor(i * ntrcvexamples/ntiles);
    ntex = topt - frompt + 1;
    
    [ntmodelres]    = createModelDayResStuct(ntex, 1, 1);
    ntmodelres.Pred = pmModelRes.pmNDayRes(1).Pred(fdsortidx(frompt:topt));
    ntlabels        = labels(fdsortidx(frompt:topt));
    ntfeatidx       = pmTrCVFeatureIndex(fdsortidx(frompt:topt), :);
    
    fprintf('Ntile %d of %d (from %4d to %4d) : DataComp %.1f%% to %.1f%% ', i, ntiles, frompt, topt, ...
        pmTrCVFeatureIndex.FDDataComp(fdsortidx(frompt)), pmTrCVFeatureIndex.FDDataComp(fdsortidx(topt)));
    
    ntmodelres = calcModelQualityScores(ntmodelres, ntlabels, ntex);
    
    fprintf('\n');
    
    fddatacompQS.NTile(i)    = i;
    fddatacompQS.FromIdx(i)  = frompt;
    fddatacompQS.ToIdx(i)    = topt;
    fddatacompQS.DCFrom(i)   = pmTrCVFeatureIndex.FDDataComp(fdsortidx(frompt));
    fddatacompQS.DCTo(i)     = pmTrCVFeatureIndex.FDDataComp(fdsortidx(topt));
    fddatacompQS.PRAUC(i)    = ntmodelres.PRAUC;
    fddatacompQS.ROCAUC(i)   = ntmodelres.ROCAUC;
    fddatacompQS.Acc(i)      = ntmodelres.Acc;
    fddatacompQS.PosAcc(i)   = ntmodelres.PosAcc;
    fddatacompQS.NegAcc(i)   = ntmodelres.NegAcc;
    
    fold = 0;
    modelcalibration = calcModelCalibration(labels(fdsortidx(frompt:topt)), ntmodelres.Pred, binedges, nbins, fold);
    ax1 = subplot(plotsdown1, plotsacross1, i, 'Parent', p1);
    sdidx = (modelcalibration.NbrInBin(modelcalibration.Fold == fold) <= smalldatathresh);
    plotModelCalibration(ax1, binmids, modelcalibration.Calibration(modelcalibration.Fold == fold), sdidx, [0.7, 0.7, 0.7], 'Blue', 'Red', sprintf('nTile %d', i));
    
end

if exist('f1', 'var')
    savePlotInDir(f1, plotname1, basedir, plotsubfolder);
    close(f1);
end

plotsacross2 = 1;
plotsdown2 = 2;
baseoutputfilename2 = sprintf('%s PredByDataCompNT%d', ...
                    basemodelresultsfile, ntiles);
plotname2 = sprintf('%s', baseoutputfilename2);
[f2, p2] = createFigureAndPanel(plotname2, 'Portrait', 'A4');
ax2t = subplot(plotsdown2, plotsacross2, 1, 'Parent', p2);
ax2f = subplot(plotsdown2, plotsacross2, 2, 'Parent', p2);

legendtext = cell(ntiles * 2, 1);

for i = 1:ntiles
    frompt = 1 + floor((i - 1) * (ntrcvexamples/ntiles));
    topt   = floor(i * ntrcvexamples/ntiles);
    ntex = topt - frompt + 1;
    
    [ntmodelres]    = createModelDayResStuct(ntex, 1, 1);
    ntmodelres.Pred = pmModelRes.pmNDayRes(1).Pred(fdsortidx(frompt:topt));
    ntlabels        = labels(fdsortidx(frompt:topt));
    ntfeatidx       = pmTrCVFeatureIndex(fdsortidx(frompt:topt), :);
    
    labelidx = ntlabels == true;
    plotPredVsDataComp(ax2t, ntmodelres.Pred(labelidx),  ntfeatidx.FDDataComp(labelidx),  colours(i, :));
    plotPredVsDataComp(ax2f, ntmodelres.Pred(~labelidx), ntfeatidx.FDDataComp(~labelidx), colours(i, :));
    
    legendtext{(i * 2) - 1} = sprintf('Ntile %d data', i);
    legendtext{(i * 2)}     = sprintf('Ntile %d avg',  i);
    
end

ax2t.FontSize = 12;
ax2f.FontSize = 12;

title(ax2t, 'True Labels');
xlabel(ax2t, 'Data Completeness');
ylabel(ax2t, 'Prediction');

title(ax2f, 'False Labels');
xlabel(ax2f, 'Data Completeness');
ylabel(ax2f, 'Prediction');

legend(ax2t, legendtext, 'Location', 'northwest');
legend(ax2f, legendtext, 'Location', 'northwest');

if exist('f2', 'var')
    savePlotInDir(f2, plotname2, basedir, plotsubfolder);
    close(f2);
end

fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'ExcelFiles';
baseoutputfilename1 = sprintf('%s QSByDataCompNT%d', basemodelresultsfile, ntiles);
fprintf('Writing data completeness QS to file%s\n', sprintf('%s.xlsx', baseoutputfilename1));
writetable(fddatacompQS,   fullfile(basedir, subfolder, sprintf('%s.xlsx', baseoutputfilename1)), 'Sheet', 'FD_DCQS');
 
toc
fprintf('\n');





