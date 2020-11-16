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

%[~, ~, pmBaselineQS] = createMissPattTables(1, 1);
% add row to Baseline QS table
%pmBaselineQS.PScore(1)      = pmModelRes.pmNDayRes.PScore;
%pmBaselineQS.ElecPScore(1)  = pmModelRes.pmNDayRes.ElecPScore;
%pmBaselineQS.AvgEpiTPred(1) = pmModelRes.pmNDayRes.AvgEpiTPred;
%pmBaselineQS.AvgEpiFPred(1) = pmModelRes.pmNDayRes.AvgEpiFPred;
%pmBaselineQS.AvgEPV(1)      = pmModelRes.pmNDayRes.AvgEPV;
%pmBaselineQS.PRAUC(1)       = pmModelRes.pmNDayRes.PRAUC;
%pmBaselineQS.ROCAUC(1)      = pmModelRes.pmNDayRes.ROCAUC;
%pmBaselineQS.Acc(1)         = pmModelRes.pmNDayRes.Acc;
%pmBaselineQS.PosAcc(1)      = pmModelRes.pmNDayRes.PosAcc;
%pmBaselineQS.NegAcc(1)      = pmModelRes.pmNDayRes.NegAcc;

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

nexamples = size(pmFeatureIndex, 1);
nrawmeasures = sum(measures.RawMeas);

tic
psplitfile = sprintf('%spatientsplit.mat', pmFeatureParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, subfolder, psplitfile));
toc
fprintf('\n');

epilen     = 7;  % temporary hardcoding - replace with feature parameter when have more time
lossfunc   = 'hinge'; % temporary hardcoding - replace with model parameter when have more time

nqcfolds = 2; % number of folds for the nested cross validation for the quality classifier

[nactmisspatts, validresponse] = selectNbrExamples('actual',    nexamples);
if validresponse == 0
    return;
end

[nsynmisspatts, validresponse] = selectNbrExamples('synthetic', nexamples);
if validresponse == 0
    return;
end
nmisspatts = nqcfolds + nactmisspatts + nsynmisspatts;
fprintf('\n');

[pmMissPattIndex, pmMissPattArray, pmMissPattQS, pmMissPattQSPct] ... 
    = createDWMissPattTables(nmisspatts, nrawmeasures, pmFeatureParamsRow.datawinduration);

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

rng(2);
[pmMissPattIndex] = createDWMissScenarios(pmMissPattIndex, nexamples, nqcfolds, nactmisspatts, nsynmisspatts);

% loop over the number of missingness patterns required
for mi = 1:nmisspatts
    qcfold = pmMissPattIndex.QCFold(mi);
    fprintf('%d of %d: Qual Classifier fold %d, Pred Classifier folds ', mi, nmisspatts, qcfold);
    fprintf('%d ', pcfolds(qcfold, :));
    fprintf('\n');
    % apply missingness pattern at random (see augment function)
    [pmMSDataWinArray, pmMissPattIndex(mi, :), pmMissPattArray(mi, :)] = applyMissPattToDataWinArray(pmDataWinArray, ...
            pmMissPattIndex(mi, :), pmMissPattArray(mi, :), measures, nmeasures, pmFeatureParamsRow);
    
    [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
        createModFeaturesFromDWArrays(pmMSDataWinArray, pmOverallStats, nexamples, measures, nmeasures, pmModFeatParamsRow);
    
     % separate out test data and keep aside
    [~, ~, ~, ~, ~, ~, ...
     pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
     trcvlabels, ~, npcfolds] ...
     = splitTestFeaturesNew(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
                            pmExABxElLabels, pmPatientSplit, nsplits);
    
    npcperqc = npcfolds/nqcfolds;
    % create index for data in qc fold (two of the pc folds)
    qcfoldidx = ismember(pmTrCVFeatureIndex.PatientNbr, pmPatientSplit.PatientNbr(ismember(pmPatientSplit.SplitNbr, pcfolds(qcfold, :))));
    
    % filter features and labels by the qc fold idx
    foldfeatindex = pmTrCVFeatureIndex(qcfoldidx, :);
    foldnormfeats = pmTrCVNormFeatures(qcfoldidx, :);
    foldlabels    = trcvlabels(qcfoldidx);
    nfoldexamples = sum(qcfoldidx);
    
    % create index for the pc fold subset within the qc fold (to determine
    % the correct model to use to predict).
    qcpcfoldidx = false(nfoldexamples, npcperqc);
    for i = 1:npcperqc
        qcpcfoldidx(:, i) = ismember(foldfeatindex.PatientNbr, pmPatientSplit.PatientNbr(ismember(pmPatientSplit.SplitNbr, pcfolds(qcfold, i))));
    end
    
    % train/predict model for 2-fold CV, but with each fold containing 2
    % folds of the predictive classifier
    % calc pred qual scores
    % store results in arrays - scenario description array, missingness pattern array and qual score
    % array
   
    [hyperparamQS, ~, foldhpCVQS, ~] = createHpQSTables(1, npcperqc);
    lrval  = pmHyperParamQS.HyperParamQS.LearnRate;
    ntrval = pmHyperParamQS.HyperParamQS.NumTrees;
    mlsval = pmHyperParamQS.HyperParamQS.MinLeafSize;
    mnsval = pmHyperParamQS.HyperParamQS.MaxNumSplit;
    fvsval = pmHyperParamQS.HyperParamQS.FracVarsToSample;
    
    runtype = pmOtherRunParams.runtype;

    tic
    if runtype == 1
        % run 2-fold cross-validation
        pmMSRes = createModelDayResStuct(nfoldexamples, npcperqc, 1);

        for fold = 1:npcperqc

            foldhpcomb = fold;
            fprintf('Fold %d: ', fold);   

            % calculate predictions and quality scores on cv data
            fprintf('CV: ');
            [foldhpCVQS, pmCVRes] = calcPredAndQS(pmModelByFold(pcfolds(qcfold, fold)).Model, foldhpCVQS, foldfeatindex(qcpcfoldidx(:, fold), :), ...
                                        foldnormfeats(qcpcfoldidx(:, fold), :), foldlabels(qcpcfoldidx(:, fold)), fold, foldhpcomb, pmAMPred, ...
                                        pmPatientSplit, pmModelParamsRow.ModelVer{1}, epilen, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);
            
            % also store results on overall model results structure
            pmMSRes.Pred(qcpcfoldidx(:, fold)) = pmCVRes.Pred;
            pmMSRes.Loss(fold)  = pmCVRes.Loss;
            
        end

        fprintf('Overall:\n');
        fprintf('CV: ');
        fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
        [pmMSRes, pmAMPredUpd] = calcAllQualScores(pmMSRes, foldlabels, nfoldexamples , pmAMPred, foldfeatindex, pmPatientSplit, epilen);
        
        fprintf('\n');
        
        % add row to MissPatt QS table
        pmMissPattQS.PScore(mi)      = pmMSRes.PScore;
        pmMissPattQS.ElecPScore(mi)  = pmMSRes.ElecPScore;
        pmMissPattQS.AvgEpiTPred(mi) = pmMSRes.AvgEpiTPred;
        pmMissPattQS.AvgEpiFPred(mi) = pmMSRes.AvgEpiFPred;
        pmMissPattQS.AvgEPV(mi)      = pmMSRes.AvgEPV;
        pmMissPattQS.PRAUC(mi)       = pmMSRes.PRAUC;
        pmMissPattQS.ROCAUC(mi)      = pmMSRes.ROCAUC;
        pmMissPattQS.Acc(mi)         = pmMSRes.Acc;
        pmMissPattQS.PosAcc(mi)      = pmMSRes.PosAcc;
        pmMissPattQS.NegAcc(mi)      = pmMSRes.NegAcc;

        hyperparamQS(1, :) = setHyperParamQSrow(hyperparamQS(1, :), lrval, ntrval, mlsval, mnsval, fvsval, pmMSRes);

        toc
        fprintf('\n');

    else
        fprintf('Unknown run mode\n');
        return
    end

end

% save baseline QS scores by fold
pmBaselineIndex = pmMissPattIndex(1:nqcfolds, :);
pmBaselineQS    = pmMissPattQS(1:nqcfolds, :);
pmMissPattIndex(1:nqcfolds, :) = [];
pmMissPattArray(1:nqcfolds, :) = [];
pmMissPattQS(1:nqcfolds, :)    = [];
pmMissPattQSPct(1:nqcfolds, :)    = [];

% populate the relative percentage QS table
for i = 1:nqcfolds
    bidx = pmBaselineIndex.QCFold == i;
    midx = pmMissPattIndex.QCFold == i;
    pmMissPattQSPct(midx, :) = array2table(table2array(pmMissPattQS(midx, :)) ./ table2array(pmBaselineQS(bidx, :)));
end

pmHyperParamsRow = struct();
pmHyperParamsRow.learnrate = lrval;
pmHyperParamsRow.numtrees = ntrval;
pmHyperParamsRow.minleafsz = mlsval;
pmHyperParamsRow.maxnumsplit = mnsval;
pmHyperParamsRow.fracvarsamp = fvsval;

pmOtherRunParams = struct();
pmOtherRunParams.btmode     = 2;
pmOtherRunParams.runtype    = runtype;
pmOtherRunParams.nbssamples = 0;
pmOtherRunParams.epilen     = epilen;
pmOtherRunParams.lossfunc   = lossfunc;

fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%s-n%d QCDataset.mat', basemodelresultsfile, nmisspatts);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmMissPattQSPct', ...
    'pmBaselineIndex', 'pmBaselineQS', 'pmModelByFold', 'nqcfolds', 'npcfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', 'measures', 'nmeasures');
toc
fprintf('\n');

beep on;
beep;
