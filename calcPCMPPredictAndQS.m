function [misspattqsrow] = calcPCMPPredictAndQS(misspattqsrow, pmModelByFold, pmTrCVFeatureIndex, ...
    pmTrCVNormFeatures, trcvlabels, pmPatientSplit, pmAMPred, ...
    qcfold, nqcfolds, npcfolds, pcfolds, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams)

% calcPCMPPredictAndQS - function runs the nested cross validation for the
% trained predictive classifier on data-set with missingness pattern
% applied, and calculates revised quality scores
 
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

%[hyperparamQS, ~, foldhpCVQS, ~] = createHpQSTables(1, npcperqc);
[~, ~, foldhpCVQS, ~] = createHpQSTables(1, npcperqc);
lrval  = pmHyperParamQS.HyperParamQS.LearnRate;
ntrval = pmHyperParamQS.HyperParamQS.NumTrees;
mlsval = pmHyperParamQS.HyperParamQS.MinLeafSize;
mnsval = pmHyperParamQS.HyperParamQS.MaxNumSplit;
fvsval = pmHyperParamQS.HyperParamQS.FracVarsToSample;

tic
if pmOtherRunParams.runtype == 1
    % run 2-fold cross-validation
    pmMSRes = createModelDayResStuct(nfoldexamples, npcperqc, 1);

    for fold = 1:npcperqc

        foldhpcomb = fold;
        fprintf('Fold %d: ', fold);   

        % calculate predictions and quality scores on cv data
        fprintf('CV: ');
        [foldhpCVQS, pmCVRes] = calcPredAndQS(pmModelByFold(pcfolds(qcfold, fold)).Model, foldhpCVQS, foldfeatindex(qcpcfoldidx(:, fold), :), ...
                                    foldnormfeats(qcpcfoldidx(:, fold), :), foldlabels(qcpcfoldidx(:, fold)), fold, foldhpcomb, pmAMPred, ...
                                    pmPatientSplit, pmModelParamsRow.ModelVer{1}, pmOtherRunParams.epilen, pmOtherRunParams.lossfunc, ...
                                    lrval, ntrval, mlsval, mnsval, fvsval, pmOtherRunParams.fpropthresh);

        % also store results on overall model results structure
        pmMSRes.Pred(qcpcfoldidx(:, fold)) = pmCVRes.Pred;
        pmMSRes.Loss(fold)  = pmCVRes.Loss;

    end

    fprintf('Overall:\n');
    fprintf('CV: ');
    fprintf('LR: %.2f LC: %3d MLS: %3d MNS: %3d - Qual Scores: ', lrval, ntrval, mlsval, mnsval);
    [pmMSRes, ~] = calcAllQualScores(pmMSRes, foldlabels, nfoldexamples , pmAMPred, foldfeatindex, ...
        pmPatientSplit, pmOtherRunParams.epilen, pmOtherRunParams.fpropthresh);
    
    fprintf('\n');

    % add row to MissPatt QS table
    misspattqsrow.PScore      = pmMSRes.PScore;
    misspattqsrow.ElecPScore  = pmMSRes.ElecPScore;
    misspattqsrow.AvgEpiTPred = pmMSRes.AvgEpiTPred;
    misspattqsrow.AvgEpiFPred = pmMSRes.AvgEpiFPred;
    misspattqsrow.AvgEPV      = pmMSRes.AvgEPV;
    misspattqsrow.PRAUC       = pmMSRes.PRAUC;
    misspattqsrow.ROCAUC      = pmMSRes.ROCAUC;
    misspattqsrow.Acc         = pmMSRes.Acc;
    misspattqsrow.PosAcc      = pmMSRes.PosAcc;
    misspattqsrow.NegAcc      = pmMSRes.NegAcc;
    misspattqsrow.TrigDelay   = pmMSRes.TrigDelay;
    misspattqsrow.EarlyWarn   = pmMSRes.EarlyWarn;
    misspattqsrow.TrigIntrTPR = pmMSRes.TrigIntrTPR;
    
    toc
    fprintf('\n');

else
    fprintf('Unknown run mode\n');
    return
end

end

