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
typetext = 'QCDRResults';
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
    'qsmeasure', 'qsthreshold', 'fpthreshold');
toc
fprintf('\n');

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

pcopthresh = fpthreshold;

[qcdrindex, qcdrmp3D, qcdrdw3D, qcdrfeats, qcdrcyclicpred] = ...
            calcPCCyclicPredsForMP(pmModelByFold, pmFeatureIndex, pmDataWinArray, pmExABxElLabels, ...
                pmAMPred, pmPatientSplit, nsplits, pmOverallStats, ...
                measures, nmeasures, nrawmeas, npcexamples, pcfolds, pmBaselineQS, ...
                qcdrindex, qcdrmp3D, qcdrdw3D, qcdrfeats, qcdrcyclicpred, ...
                qcdrindex, qcdrmp3D, mpdur, dwdur, totalwin, cyclicdur, iscyclic, pcopthresh, qsmeasure, ...
                pmFeatureParamsRow, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, pmModFeatParamsRow);

fprintf('Min cyclic Inner (Predictive) classifier predicted %%age EPV of baseline: %.2f%%\n', 100 * qcdrindex.SelPred(2));
fprintf('All cyclic preds: ');
fprintf('%.4f%% ', 100 * qcdrcyclicpred(2, :));
fprintf('\n');
fprintf('\n');




%[mpindex, mparray, mpqs, mpqspct] = createDWMissPattTables(nqcfolds, nrawmeas, dwdur);
%[mpindex, mparray, mpqs, mpqspct] = createDWMissPattTables(1, nrawmeas, dwdur);

%mpindex.ScenType(:) = 8;
%mpindex.Scenario(:) = {'MinDataRule'};
%mpindex.QCFold(:) = 1:nqcfolds;
%mpindex.QCFold(:) = 1;

% need to explode min data rules miss patt (factoring norm
% window as well as data window) to create 35 day pattern
%[qcdrtw2Dam] = convertMP2DtoDW2D(reshape(qcdrmp3D, [nrawmeas, mpdur]), measures, nmeasures, mpdur, totalwin);

%qcdrmp2D = reshape(qcdrmp3D, [nrawmeas, mpdur]);
%[qcdrtw2D] = convertMPtoDW(qcdrmp2D, mpdur, totalwin);
% and now explode back out to all measures
%qcdrtw2Dam = zeros(nmeasures, totalwin);
%qcdrtw2Dam(logical(measures.RawMeas), :) = qcdrtw2D;

%for mi = 1:nqcfolds
%        qcfold = mpindex.QCFold(mi);
%        fprintf('%d of %d: Qual Classifier fold %d, Pred Classifier folds ', mi, nqcfolds, qcfold);
%        fprintf('%d ', pcfolds(qcfold, :));
%        fprintf('\n');
        
%    % apply missingness pattern to whole dataset
%    [pmMSDataWinArray, mpindex(mi, :), mparray(mi, :)] = applyMissPattToDataWinArray(pmDataWinArray, ...
%            mpindex(mi, :), mparray(mi, :), measures, nmeasures, pmFeatureParamsRow, qcdrtw2Dam);

%    if any(qcdrfeats - mparray(mi, :))
%        fprintf('**** Generated missing pattern array does not match original from min data rules result ****\n');
%        return
%    end

%    % create model features for whole dataset for inner classifier
%    [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
%        createModFeaturesFromDWArrays(pmMSDataWinArray, pmOverallStats, npcexamples, measures, nmeasures, pmModFeatParamsRow);

%    % separate out test data and keep aside
%    [~, ~, ~, ~, ~, ~, pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
%        trcvlabels, ~, npcfolds] = splitTestFeaturesNew(pmFeatureIndex, ...
%        pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
%        pmExABxElLabels, pmPatientSplit, nsplits);

%    [mpqs(mi, :)] = calcPCMPPredictAndQS(mpqs(mi, :), pmModelByFold, pmTrCVFeatureIndex, ...
%        pmTrCVNormFeatures, trcvlabels, pmPatientSplit, pmAMPred, ...
%        qcfold, nqcfolds, npcfolds, pcfolds, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, ...
%        pmOtherRunParams.epilen, pmOtherRunParams.lossfunc);

%end

% populate the relative percentage QS table - use average of baselines for
% the two original quality classifier folds
%for i = 1:nqcfolds
%    %bidx = pmBaselineIndex.QCFold == i;
%    midx = mpindex.QCFold == i;
%    %mpqspct(midx, :) = array2table(table2array(mpqs(midx, :)) ./ table2array(pmBaselineQS(bidx, :)));
%    mpqspct(midx, :) = array2table(table2array(mpqs(midx, :)) ./ mean(table2array(pmBaselineQS)));
%end

%fprintf('Inner (Predictive) classifier EPV on Min Data Pattern:        %.2f\n', mpqs.AvgEPV);
%fprintf('Inner (Predictive) classifier EPV on Baseline:                %.2f\n', mean(pmBaselineQS.AvgEPV));
%fprintf('Inner (Predictive) classifier predicted %%age EPV of baseline: %.2f%%\n', 100 * mpqspct.AvgEPV);

%fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = strrep(qcdrresfile, 'QCDRResults', 'TestQCDRRes');
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'qcdrindex', 'qcdrmp3D', 'qcdrdw3D', 'qcdrfeats', 'qcdrcyclicpred', ...
    'qcdrmeasures', 'nrawmeas', 'dwdur', 'mpdur', 'mpstartex', 'iscyclic', 'cyclicdur', 'idx', ...
    'pmQCModelRes', 'pmQCFeatNames', ...
    'pmBaselineIndex', 'pmBaselineQS', 'nqcfolds', ...
    'pmModelByFold', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams', ...
    'pmMPModelParamsRow', 'pmMPHyperParamsRow', 'pmMPOtherRunParams', ...
    'qsmeasure', 'qsthreshold', 'fpthreshold', 'pcopthresh', ...
    'normwin', 'totalwin', 'npcexamples', ...
    'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmAMPred', 'measures', 'nmeasures', 'pmOverallStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

