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

if pmFeatureParamsRow.augmethod == 1
    dataresultsfile = modelresultsfile;
else
    findaugtext = sprintf('-au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('-au1');
    dataresultsfile = strrep(modelresultsfile, findaugtext, replaceaugtext);
end

if pmFeatureParamsRow.interpmethod ~= 0 && pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern script only works on data with either no or full interpolation\n');
    return
end

pmModelByFold = pmModelRes.pmNDayRes.Folds;
nfolds = size(pmModelByFold, 2);

[~, ~, pmBaselineQS] = createMissPattTables(1, 1);
% add row to Baseline QS table
pmBaselineQS.PScore(1)      = pmModelRes.pmNDayRes.PScore;
pmBaselineQS.ElecPScore(1)  = pmModelRes.pmNDayRes.ElecPScore;
pmBaselineQS.AvgEpiTPred(1) = pmModelRes.pmNDayRes.AvgEpiTPred;
pmBaselineQS.AvgEpiFPred(1) = pmModelRes.pmNDayRes.AvgEpiFPred;
pmBaselineQS.AvgEPV(1)      = pmModelRes.pmNDayRes.AvgEPV;
pmBaselineQS.PRAUC(1)       = pmModelRes.pmNDayRes.PRAUC;
pmBaselineQS.ROCAUC(1)      = pmModelRes.pmNDayRes.ROCAUC;
pmBaselineQS.Acc(1)         = pmModelRes.pmNDayRes.Acc;
pmBaselineQS.PosAcc(1)      = pmModelRes.pmNDayRes.PosAcc;
pmBaselineQS.NegAcc(1)      = pmModelRes.pmNDayRes.NegAcc;

clear('pmModelRes');

% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
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
plotbyfold = 0; % set to 1 if you want to print the pr & roc curves by fold

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);

[nmisspatts, validresponse] = selectNbrExamples(nexamples);
if validresponse == 0
    return;
end

rng(2);
[pmMissPattIndex, pmMissPattArray, pmMissPattQS] = createDWMissPattTables(nmisspatts, nrawmeasures, pmFeatureParamsRow.datawinduration);
randmpidx = randperm(nexamples, nmisspatts);
%randmpidx(1) = 1260;
%randmpidx(2) = 6880;

% loop over the number of missingness patterns required
for mi = 1:nmisspatts
    
    % apply missingness pattern at random (see augment function)
    [pmMSDataWinArray, pmMissPattIndex(mi, :), pmMissPattArray(mi, :)] = applyMissPattToDataWinArray(pmDataWinArray, ...
            pmMissPattIndex(mi, :), pmMissPattFeats(mi, :), randmpidx(mi), measures, nmeasures, pmFeatureParamsRow, []);
    
    fprintf('%4d of %4d: Actual missingness from example %5d with overall missingness of %2.2f%%\n', ...
        mi, nmisspatts, randmpidx(mi), sum(pmMissPattArray(mi, :)) * 100 / (pmFeatureParamsRow.datawinduration * sum(measures.RawMeas)));
    
    [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
        createModFeaturesFromDWArrays(pmMSDataWinArray, pmOverallStats, nexamples, measures, nmeasures, pmModFeatParamsRow);
    
     % separate out test data and keep aside
    [pmTestFeatureIndex, pmTestMuIndex, pmTestSigmaIndex, pmTestNormFeatures, ...
     pmTestExABxElLabels, pmTestPatientSplit, ...
     pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, ...
     pmTrCVExABxElLabels, pmTrCVPatientSplit, nfolds] ...
     = splitTestFeaturesNew(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
                            pmExABxElLabels, pmPatientSplit, nsplits);
                        
    % train/predict model for 4-fold CV
    % calc pred qual scores
    % store results in arrays - scenario description array, missingness pattern array and qual score
    % array
    
    trcvlabels = pmTrCVExABxElLabels;

    [hyperparamQS, ~, foldhpCVQS, ~] = createHpQSTables(1, nfolds);
    lrval  = pmHyperParamQS.HyperParamQS.LearnRate;
    ntrval = pmHyperParamQS.HyperParamQS.NumTrees;
    mlsval = pmHyperParamQS.HyperParamQS.MinLeafSize;
    mnsval = pmHyperParamQS.HyperParamQS.MaxNumSplit;
    fvsval = pmHyperParamQS.HyperParamQS.FracVarsToSample;
    
    runtype = pmOtherRunParams.runtype;

    tic
    if runtype == 1
        % run n-fold cross-validation
        origidx = pmTrCVFeatureIndex.ScenType == 0;
        norigex = sum(origidx);
        pmMSRes = createModelDayResStuct(norigex, nfolds, 1);

        for fold = 1:nfolds

            foldhpcomb = fold;

            fprintf('Fold %d: ', fold);

            [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
             pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] ...
                = splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold);

            origcvidx = cvidx & pmTrCVFeatureIndex.ScenType == 0;               

            % calculate predictions and quality scores on cv data
            fprintf('CV: ');
            [foldhpCVQS, pmCVRes] = calcPredAndQS(pmModelByFold(fold).Model, foldhpCVQS, pmTrCVFeatureIndex(origcvidx, :), ...
                                        pmTrCVNormFeatures(origcvidx, :), trcvlabels(origcvidx), fold, foldhpcomb, pmAMPred, ...
                                        pmPatientSplit, pmModelParamsRow.ModelVer{1}, epilen, lossfunc, ...
                                        lrval, ntrval, mlsval, mnsval, fvsval);
            
            % also store results on overall model results structure
            pmMSRes.Pred(origcvidx) = pmCVRes.Pred;
            pmMSRes.Loss(fold)  = pmCVRes.Loss;
            
        end

        fprintf('Overall:\n');
        fprintf('CV: ');
        fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
        [pmMSRes, pmAMPredUpd] = calcAllQualScores(pmMSRes, trcvlabels(origidx), norigex, pmAMPred, pmTrCVFeatureIndex(origidx, :), pmPatientSplit, epilen);
        
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
outputfilename = sprintf('%s-n%d MPRes.mat', basemodelresultsfile, nmisspatts);
fprintf('Saving model output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), ...
    'pmMissPattIndex', 'pmMissPattArray', 'pmMissPattQS', 'pmBaselineQS', 'pmModelByFold', 'nfolds', ...
    'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamsRow', 'pmOtherRunParams', 'measures', 'nmeasures');
toc
fprintf('\n');

beep on;
beep;
