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
typetext = 'QCResults';
[basemodelresultsfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
modelresultsfile = sprintf('%s.mat', basemodelresultsfile);
basemodelresultsfile = strrep(basemodelresultsfile, typetext, '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading quality classifier results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
        'pmQCModelRes', 'pmQCFeatNames', ...
        'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
        'labels', 'qcsplitidx', 'nexamples', ...
        'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
        'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
        'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'measures', 'nmeasures', 'qsmeasure', 'qsthreshold', 'fpthreshold');

toc
fprintf('\n');

plotsubfolder = sprintf('Plots/QC/%s', basemodelresultsfile);
mkdir(fullfile(basedir, plotsubfolder));

[plottype, validresponse] = selectQCPlotType;
if ~validresponse
    return;
end

if plottype == 1
    % plot weights
    fprintf('Plotting Model Weights\n');
    plotQCModelWeights(pmQCModelRes, pmMissPattArray, ...
        pmFeatureParamsRow.datawinduration, pmMPModelParamsRow.ModelVer, nqcfolds, ...
        plotsubfolder, basemodelresultsfile);
elseif plottype == 2    
    % plot PR and ROC Curves
    fprintf('Plotting PR and ROC Curves\n');
    plotQCPRAndROCCurves(pmQCModelRes, plotsubfolder, basemodelresultsfile)
elseif plottype == 3
    % plot missingness vs qs by type of quality measure
    %[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);
    plotMissingnessQSFcn(pmQCModelRes, pmMissPattIndex, pmMissPattQSPct, labels, ...
        qsthreshold, fpthreshold, pmQCModelRes.PredOp, basemodelresultsfile, plotsubfolder);
elseif plottype == 4
    % plot missingness vs qs by measure
    %[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);
    plotMissQSByMeasFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
        qsthreshold, fpthreshold, pmQCModelRes.PredOp, measures, pmFeatureParamsRow.datawinduration, basemodelresultsfile, plotsubfolder, 'AvgEPV');
elseif plottype == 5
    % plot missingness vs qs by model outcome
    %[rocthresh, rocthreshidx] = calculateROCOpThresh(pmQCModelRes.FPR, pmQCModelRes.TPR, pmQCModelRes.PredSort);
    plotMissQSByOutcomeFcn(pmQCModelRes, pmMissPattArray, pmMissPattQSPct, labels, ...
        qsthreshold, fpthreshold, pmQCModelRes.PredOp, measures, pmFeatureParamsRow.datawinduration, basemodelresultsfile, plotsubfolder, 'AvgEPV');
elseif plottype == 6
    % plot calibration curve
    calcAndPlotQCCalibration(pmQCModelRes, labels, pmMissPattIndex, nqcfolds, basemodelresultsfile, plotsubfolder);
elseif plottype == 7
    % plot decision tree
    [fold, validresponse] = selectFold(size(pmQCModelRes.Folds, 2));
    if ~validresponse
        return;
    end
    [tree, validresponse] = selectTree(size(pmQCModelRes.Folds(1).Model.Trained, 1));
    if ~validresponse
        return;
    end
    % **** add function in here ****
    
elseif plottype == 8
    % plot analysis of examples by leaf
    
end


