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
qcbaselinefile = strrep(basemodelresultsfile, ' ModelResults', 'QCBaseline');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading trained predictive model and run parameters for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');

if pmFeatureParamsRow.interpmethod ~= 0 && pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern script only works on data with either no or full interpolation\n');
    return
end

pmModelByFold = pmModelRes.pmNDayRes.Folds;
clear('pmModelRes');

% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
if pmFeatureParamsRow.augmethod > 1
    findaugtext = sprintf('au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('au1');
    featureparamsfile = strrep(featureparamsfile, findaugtext, replaceaugtext);
end
featureparamsfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, featureparamsfile), 'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

tic
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time
nqcfolds = 2; % number of folds for the nested cross validation for the quality classifier

npcexamples = size(pmFeatureIndex, 1);
nrawmeasures = sum(measures.RawMeas);

[pmBaselineIndex, ~, pmBaselineQS, pmBaselineQSPct] ... 
    = createDWMissPattTables(nqcfolds, nrawmeasures, pmFeatureParamsRow.datawinduration);

for n = 1:nqcfolds
    pmBaselineIndex.ScenType(n) = 0;
    pmBaselineIndex.Scenario{n} = 'None';
    pmBaselineIndex.QCFold(n)   = n;
end

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

% loop over the number of missingness patterns required
for mi = 1:nqcfolds
    qcfold = pmBaselineIndex.QCFold(mi);
    fprintf('Baseline: %d of %d: Qual Classifier fold %d, Pred Classifier folds ', mi, nqcfolds, qcfold);
    fprintf('%d ', pcfolds(qcfold, :));
    fprintf('\n');
    
    [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
        createModFeaturesFromDWArrays(pmDataWinArray, pmOverallStats, npcexamples, measures, nmeasures, pmModFeatParamsRow);

    % separate out test data and keep aside
    [~, ~, ~, ~, ~, ~, pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
        trcvlabels, ~, npcfolds] = splitTestFeaturesNew(pmFeatureIndex, ...
        pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
        pmExABxElLabels, pmPatientSplit, nsplits);

    [pmBaselineQS(mi, :)] = calcPCMPPredictAndQS(pmBaselineQS(mi, :), pmModelByFold, pmTrCVFeatureIndex, ...
        pmTrCVNormFeatures, trcvlabels, pmPatientSplit, pmAMPred, ...
        qcfold, nqcfolds, npcfolds, pcfolds, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, ...
        epilen, lossfunc);
end


pmHyperParamsRow = struct();
pmHyperParamsRow.learnrate   = pmHyperParamQS.HyperParamQS.LearnRate;
pmHyperParamsRow.numtrees    = pmHyperParamQS.HyperParamQS.NumTrees;
pmHyperParamsRow.minleafsz   = pmHyperParamQS.HyperParamQS.MinLeafSize;
pmHyperParamsRow.maxnumsplit = pmHyperParamQS.HyperParamQS.MaxNumSplit;
pmHyperParamsRow.fracvarsamp = pmHyperParamQS.HyperParamQS.FracVarsToSample;

    
pmOtherRunParams.btmode     = 2;
% no need to update runtype
pmOtherRunParams.nbssamples = 0;
pmOtherRunParams.epilen     = epilen;
pmOtherRunParams.lossfunc   = lossfunc;
pmOtherRunParams.nqcfolds   = nqcfolds;

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%s.mat', qcbaselinefile);
fprintf('Saving baseline quality scores to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmBaselineIndex', 'pmBaselineQS', 'pmModelByFold', 'nqcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', ...
    'measures', 'nmeasures');
toc
fprintf('\n');

beep on;
beep;
