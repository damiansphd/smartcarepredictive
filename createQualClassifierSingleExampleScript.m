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

basemodelresultsfile = shortenQCFileName(basemodelresultsfile, pmHyperParamQS.HyperParamQS);
qcbaselinefile = strrep(basemodelresultsfile, ' ModelResults', 'QCBaseline');

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

tic
fprintf('Loading baseline quality scores from file %s\n', qcbaselinefile);
load(fullfile(basedir, subfolder, sprintf('%s.mat', qcbaselinefile)), 'pmBaselineIndex', 'pmBaselineQS');
toc
fprintf('\n');


nqcfolds = 2; % number of folds for the nested cross validation for the quality classifier

npcexamples = size(pmFeatureIndex, 1);
nrawmeasures = sum(measures.RawMeas);

[pmSingleExIndex, pmSingleExArray, pmSingleExQS, ~] ... 
    = createDWMissPattTables(1, nrawmeasures, pmFeatureParamsRow.datawinduration);

n = 1;
% Populate single example index with details of the single scenario to run for
%pmSingleExIndex.ScenType(n) = 0;
%pmSingleExIndex.Scenario{n} = 'Baseline';
%pmSingleExIndex.MSExample(n) = 0;
%pmSingleExIndex.QCFold(n)   = 1;

%pmSingleExIndex.ScenType(n) = 4;
%pmSingleExIndex.Scenario{n} = 'Actual';
%pmSingleExIndex.MSExample(n) = 1275;
%pmSingleExIndex.QCFold(n)   = 2;

pmSingleExIndex.ScenType(n) = 4;
pmSingleExIndex.Scenario{n} = 'Actual';
pmSingleExIndex.MSExample(n) = 434;
pmSingleExIndex.QCFold(n)   = 1;

%pmSingleExIndex.ScenType(n) = 4;
%pmSingleExIndex.Scenario{n} = 'Actual';
%pmSingleExIndex.MSExample(n) = 431;
%pmSingleExIndex.QCFold(n)   = 2;

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

% loop over the number of missingness patterns required
mi = 1;
qcfold = pmSingleExIndex.QCFold(mi);
fprintf('Single Example: Qual Classifier fold %d, Pred Classifier folds ', qcfold);
fprintf('%d ', pcfolds(qcfold, :));
fprintf('\n');

% apply missingness pattern to dataset (see augment function)
[pmMSDataWinArray, pmSingleExIndex(mi, :), pmSingleExArray(mi, :)] = applyMissPattToDataWinArray(pmDataWinArray, ...
        pmSingleExIndex(mi, :), pmSingleExArray(mi, :), measures, nmeasures, pmFeatureParamsRow, []);
    
[pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
        createModFeaturesFromDWArrays(pmMSDataWinArray, pmOverallStats, npcexamples, measures, nmeasures, pmModFeatParamsRow);

% separate out test data and keep aside
[~, ~, ~, ~, ~, ~, pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
    trcvlabels, ~, npcfolds] = splitTestFeaturesNew(pmFeatureIndex, ...
    pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
    pmExABxElLabels, pmPatientSplit, nsplits);

[pmSingleExQS(mi, :)] = calcPCMPPredictAndQS(pmSingleExQS(mi, :), pmModelByFold, pmTrCVFeatureIndex, ...
    pmTrCVNormFeatures, trcvlabels, pmPatientSplit, pmAMPred, ...
    qcfold, nqcfolds, npcfolds, pcfolds, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams);


pmHyperParamsRow = struct();
pmHyperParamsRow.learnrate   = pmHyperParamQS.HyperParamQS.LearnRate;
pmHyperParamsRow.numtrees    = pmHyperParamQS.HyperParamQS.NumTrees;
pmHyperParamsRow.minleafsz   = pmHyperParamQS.HyperParamQS.MinLeafSize;
pmHyperParamsRow.maxnumsplit = pmHyperParamQS.HyperParamQS.MaxNumSplit;
pmHyperParamsRow.fracvarsamp = pmHyperParamQS.HyperParamQS.FracVarsToSample;

    
pmOtherRunParams.btmode     = 2;
pmOtherRunParams.nbssamples = 0;
pmOtherRunParams.nqcfolds   = nqcfolds;
% no need to update runtype, epilen, lossfunc, fpropthresh
%pmOtherRunParams.epilen     = epilen;
%pmOtherRunParams.lossfunc   = lossfunc;


beep on;
beep;
