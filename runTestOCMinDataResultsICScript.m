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

fprintf('Select Outer (Quality) Classifier Data Rules model results file\n');
typetext = 'QCDRResultsOCNew';
[baseqcdrresfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcdrresfile = sprintf('%s.mat', baseqcdrresfile);
baseqcdrresfile = strrep(baseqcdrresfile, typetext, '');

fprintf('Select Inner (Predictive) Classifier model results file\n');
[basepcresfile] = selectModelResultsFile(fv1, lb1, rm1);
pcresfile = sprintf('%s.mat', basepcresfile);

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading Outer (Quality) classifier data rules results for %s\n', qcdrresfile);
load(fullfile(basedir, subfolder, qcdrresfile), ...
    'pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmQCModelRes', 'pmQCFeatNames', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
    'pmQSConstr');
    
%   'qsmeasure', 'qsthreshold', 'fpthreshold');

toc
fprintf('\n');

% backward compatibility issue since I changed the quality classifier
% to handle more than one QS constraint - it's hard to easily fit multiple
% qs scores into the single SelPred column for the pmQCDRIndex table - so
% for now just use AvgEPV constraint as this is 99.9% the same as both
% constraints.
pmQSConstr = pmQSConstr(ismember(pmQSConstr.qsmeasure, {'AvgEPV'}), :);


qcdrindex      = pmQCDRIndex(idx, :);
qcdrmp3D       = pmQCDRMissPatt(idx, :, :);
qcdrdw3D       = pmQCDRDataWin(idx, :, :);
qcdrfeats      = pmQCDRFeatures(idx, :);
qcdrcyclicpred = pmQCDRCyclicPred(idx, :);
clear('pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading trained Inner (Predictive) classifier and run parameters for %s\n', pcresfile);
load(fullfile(basedir, subfolder, pcresfile), ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');
toc
fprintf('\n');

pmModelByFold = pmModelRes.pmNDayRes.Folds;
clear('pmModelRes');

normwin = pmFeatureParamsRow.normwinduration;
totalwin = dwdur + normwin;

% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
if pmFeatureParamsRow.augmethod > 1
    findaugtext = sprintf('au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('au1');
    featureparamsfile = strrep(featureparamsfile, findaugtext, replaceaugtext);
end
featureparamsfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading Inner (Predictive) model input data for %s\n', featureparamsfile);
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

npcexamples = size(pmFeatureIndex, 1);

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

%pcopthresh = fpthreshold;

[qcdrindex, qcdrmp3D, qcdrdw3D, qcdrfeats, qcdrcyclicpred] = ...
            calcPCCyclicPredsForMP(pmModelByFold, pmFeatureIndex, pmDataWinArray, pmExABxElLabels, ...
                pmAMPred, pmPatientSplit, nsplits, pmOverallStats, ...
                measures, nmeasures, nrawmeas, npcexamples, pcfolds, pmBaselineQS, ...
                qcdrindex, qcdrmp3D, qcdrdw3D, qcdrfeats, qcdrcyclicpred, ...
                qcdrindex, qcdrmp3D, mpdur, dwdur, totalwin, cyclicdur, iscyclic, pmQSConstr, ...
                pmFeatureParamsRow, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, pmModFeatParamsRow);

fprintf('Min cyclic Inner (Predictive) classifier predicted %%age EPV of baseline: %.2f%%\n', 100 * qcdrindex.SelPred(2));
fprintf('All cyclic preds: ');
fprintf('%.4f%% ', 100 * qcdrcyclicpred(2, :));
fprintf('\n');
fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = strrep(qcdrresfile, typetext, sprintf('Test%s', typetext));
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'qcdrindex', 'qcdrmp3D', 'qcdrdw3D', 'qcdrfeats', 'qcdrcyclicpred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmQCModelRes', 'pmQCFeatNames', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmModelByFold', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
    'pmQSConstr', ...
    'normwin', 'totalwin', 'npcexamples', ...
    'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

