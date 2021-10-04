function [pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
    calcPCCyclicPredsForMP(pmModelByFold, pmFeatureIndex, pmDataWinArray, pmExABxElLabels, ...
        pmAMPred, pmPatientSplit, nsplits, pmOverallStats, ...
        measures, nmeasures, nrawmeas, npcexamples, pcfolds, pmBaselineQS, ...
        pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
        qcdrindexrow, qcdrmp3D, mpdur, dwdur, totalwin, cyclicdur, iscyclic, pmQSConstr, ...
        pmFeatureParamsRow, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams, pmModFeatParamsRow)

% calcPCCyclicPredsForMP - run the predictive classifier for the whole dataset with a given
% missingness pattern applied and all cyclic versions and returns the results
% appended to the tables/arrays.

qcdrcycpredrow = zeros(1, cyclicdur);
qcdrmp2D = reshape(qcdrmp3D, [nrawmeas, mpdur]);

qcfold = 1;
nqcfolds = 1;

% add fprintf to show progress

for c = 1:cyclicdur
    
    fprintf('Performing cyclic prediction %d of %d\n', c, cyclicdur);
    
    % cycle the missingness pattern array and recreate features
    if iscyclic == 'Y'
        [qcdrmp2D] = cycleMPArray(qcdrmp2D);
    end
    [qcdrtw2Dam]  = convertMP2DtoDW2D(qcdrmp2D, measures, nmeasures, mpdur, totalwin);
    
    [mpindex, mparray, mpqs, mpqspct] = createDWMissPattTables(1, nrawmeas, dwdur);
    mpindex.ScenType = 8;
        
    % apply missingness pattern to whole dataset
    [pmMSDataWinArray, ~, ~] = applyMissPattToDataWinArray(pmDataWinArray, ...
            mpindex, mparray, measures, nmeasures, pmFeatureParamsRow, qcdrtw2Dam);    
        
    % create model features for whole dataset for inner classifier
    [pmNormFeatures, ~, pmMuIndex, pmSigmaIndex, ~, ~, ~, ~, ~, ~, ~, ~] = ...
        createModFeaturesFromDWArrays(pmMSDataWinArray, pmOverallStats, npcexamples, measures, nmeasures, pmModFeatParamsRow);

    % separate out test data and keep aside
    [~, ~, ~, ~, ~, ~, pmTrCVFeatureIndex, ~, ~, pmTrCVNormFeatures, ...
        trcvlabels, ~, npcfolds] = splitTestFeaturesNew(pmFeatureIndex, ...
        pmMuIndex, pmSigmaIndex, pmNormFeatures, ...
        pmExABxElLabels, pmPatientSplit, nsplits);

    [mpqs] = calcPCMPPredictAndQS(mpqs, pmModelByFold, pmTrCVFeatureIndex, ...
        pmTrCVNormFeatures, trcvlabels, pmPatientSplit, pmAMPred, ...
        qcfold, nqcfolds, npcfolds, pcfolds, pmModelParamsRow, pmHyperParamQS, pmOtherRunParams);

    mpqspct(1, :) = array2table(table2array(mpqs) ./ mean(table2array(pmBaselineQS)));
    
%    qcdrcycpredrow(c) = mpqspct{1, qsmeasure};
    qcdrcycpredrow(c) = mpqspct{1, pmQSConstr.qsmeasure{1}};

end

qcdrindexrow.SelPred = min(qcdrcycpredrow);
%if qcdrindexrow.SelPred < (pcopthresh / 100)
if qcdrindexrow.SelPred < pmQSConstr.fpthresh(1)
    qcdrindexrow.MoveAccepted = false;
else
    qcdrindexrow.MoveAccepted = true;
end

[qcdrdw2D]    = convertMPtoDW(qcdrmp2D, mpdur, dwdur);
[qcdrfeatrow] = convertDWtoFeatures(qcdrdw2D, nrawmeas, dwdur);

[pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred] = ...
        addQCDRRows(pmQCDRIndex, pmQCDRMissPatt, pmQCDRDataWin, pmQCDRFeatures, pmQCDRCyclicPred, ...
            qcdrindexrow, reshape(qcdrmp2D, [1, nrawmeas, mpdur]), reshape(qcdrdw2D, [1, nrawmeas, dwdur]), qcdrfeatrow, qcdrcycpredrow);
            

end

