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
fprintf('Loading predictive model results data for %s\n', modelresultsfile);
load(fullfile(basedir, subfolder, modelresultsfile), ...
            'pmTestFeatureIndex', 'pmTestMuIndex', 'pmTestSigmaIndex', 'pmTestNormFeatures', ...
            'pmTestIVLabels', 'pmTestExLabels', 'pmTestABLabels', 'pmTestExLBLabels', 'pmTestExABLabels', 'pmTestExABxElLabels', ...
            'pmTestPatientSplit', ...
            'pmTrCVFeatureIndex', 'pmTrCVMuIndex', 'pmTrCVSigmaIndex', 'pmTrCVNormFeatures', ...
            'pmTrCVIVLabels', 'pmTrCVExLabels', 'pmTrCVABLabels', 'pmTrCVExLBLabels', 'pmTrCVExABLabels', 'pmTrCVExABxElLabels',...
            'pmTrCVPatientSplit', ...
            'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmHyperParamQS', 'pmOtherRunParams');

        % added for backward compatibility
if exist('pmTrCVExABxElLabels', 'var') ~= 1
    pmTrCVExABxElLabels = [];
end

if pmFeatureParamsRow.interpmethod ~= 1
    fprintf('Missingness pattern script only works on fully interpolated data\n');
    return
end

ntrcvexamples = size(pmTrCVNormFeatures, 1);

[nmisspatts, validresponse] = selectNbrExamples(ntrcvexamples);
if validresponse == 0
    return;
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

% load feature index and normfeatures from uninterpolated data set to use
% for actual missingness patterns
featureparamsfile = generateFileNameFromFullFeatureParams(pmFeatureParamsRow);
featureparamsfile = sprintf('%s.mat', featureparamsfile);
mspatfeatfile = strrep(featureparamsfile, 'ip1', 'ip0');
fprintf('Loading predictive model input data for %s\n', featureparamsfile);
load(fullfile(basedir, subfolder, mspatfeatfile), 'pmFeatureIndex', 'pmNormFeatures', 'pmNormFeatNames', 'pmAMPred', 'measures', 'nmeasures');
pmMSFeatIdx       = pmFeatureIndex;
pmMSNormFeats     = pmNormFeatures;
pmMSNormFeatNames = pmNormFeatNames;
clear('pmFeatureIndex', 'pmNormFeatures', 'pmNormFeatureNames');
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
plotbyfold = 0; % set to 1 if you want to print the pr & roc curves by fold

plotsubfolder = sprintf('Plots/%s', basemodelresultsfile);

% copy pmNormFeatures to pmOrigNormFeatures
% should add logic here for run mode eventually
pmOrigNormFeatures = pmTrCVNormFeatures;
nrawfeatures = sum(contains(pmMSNormFeatNames, {'RM'}));

rng(2);
[pmMissPattIndex, pmMissPattArray, pmMissPattQS] = createMissPattTables(nmisspatts, nrawfeatures);
randmpidx = randperm(ntrcvexamples, nmisspatts); % should this be number of overall examples ? I think so

% add for loop here over number of missingness patterns required
for mi = 1:nmisspatts
    
    fprintf('%4d of %4d: Actual missingness from example %5d\n') 
    % restore orig norm features to normfeatures
    pmTrCVNormFeatures = pmOrigNormFeatures;

    % apply missingness pattern at random (see augment function)
    [pmTrCVNormFeatures, pmMissPattIndex(mi, :), pmMissPattArray(mi, :)] = ...
        applyActMissPattToDataSet(pmTrCVNormFeatures, pmMissPattIndex(mi, :), ...
            pmMSNormFeats, randmpidx(mi), nrawfeatures, pmFeatureParamsRow.msconst);
    
    fprintf('%4d of %4d: Actual missingness from example %5d with overall missingness of %2.2f%%\n', mi, nmisspatts, randmpidx(mi), sum(pmMissPattArray(mi, :)) * 100 / nrawfeatures);
        
    %   train/predict model for 4-fold CV
    %   calc pred qual scores
    %   store results in arrays - scenario description array, missingness pattern array and qual score
    %   array

    [labels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels);
    trcvlabels = labels(:);

    % for the 'Ex Start to Treatment' label, there is only one task.
    % for the other label methods, use the predictionduration from the
    % feature parameters record
    if (pmModelParamsRow.labelmethod == 5 || pmModelParamsRow.labelmethod == 6)
        predictionduration = 1;
    else
        fprintf('These models only support label method 5 and 6\n');
        return;
    end

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
