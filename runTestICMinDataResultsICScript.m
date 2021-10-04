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

fprintf('Select Inner (Predictive) Classifier Min Data Rules results file\n');
typetext = 'QCDRResultsIC';
[baseqcdrresfile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcdrresfile = sprintf('%s.mat', baseqcdrresfile);
baseqcdrresfile = strrep(baseqcdrresfile, typetext, '');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
fprintf('Loading Inner (Predictive) Classifier Min Data Rules results for %s\n', qcdrresfile);
load(fullfile(basedir, subfolder, qcdrresfile), ...
    'pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmMissPattArray', 'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmQSConstr', ...
    'pmModelByFold', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams', ...
    'normwin', 'totalwin', 'npcexamples', ...
    'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');

%   'qsmeasure', 'qsthreshold', 'fpthreshold', ...
toc
fprintf('\n');

qcdrindex      = pmQCDRIndex(idx, :);
qcdrmp3D       = pmQCDRMissPatt(idx, :, :);
qcdrdw3D       = pmQCDRDataWin(idx, :, :);
qcdrfeats      = pmQCDRFeatures(idx, :);
qcdrcyclicpred = pmQCDRCyclicPred(idx, :);
clear('pmQCDRIndex', 'pmQCDRMissPatt', 'pmQCDRDataWin', 'pmQCDRFeatures', 'pmQCDRCyclicPred');

tic
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

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
outputfilename = strrep(qcdrresfile, typetext, 'TestQCDRResIC');
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'qcdrindex', 'qcdrmp3D', 'qcdrdw3D', 'qcdrfeats', 'qcdrcyclicpred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmMissPattArray', 'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'qsmeasure', 'qsthreshold', 'fpthreshold', 'pcopthresh', ...
    'pmModelByFold', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams', ...
    'normwin', 'totalwin', 'npcexamples', ...
    'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

