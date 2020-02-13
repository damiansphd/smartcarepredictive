function [foldhptable, pmRes, ampredupd] = calcPredAndQS(mdl, foldhptable, featidx, features, labels, fold, foldhpcomb, ampred, ...
                        patientsplit, modelver, epilen,  lossfunc, lrval, ntrval, mlsval, mnsval, fvsval)

% calcPredAndQS - wrapper function to create predictions and quality
% metrics

nexamples = size(features, 1);
pmRes     = createModelDayResStuct(nexamples, 1, 0);
% create predictions
pmRes     = predictPredModel(pmRes, mdl, features, labels, modelver, lossfunc);
fprintf('LR: %.2f NT: %3d MLS: %3d MNS: %3d FVS: %.2f- ', lrval, ntrval, mlsval, mnsval, fvsval);
fprintf('Loss: %.6f ', pmRes.Loss);

% calculate training set quality scores
[pmRes, ampredupd] = calcAllQualScores(pmRes, labels, nexamples, ampred, featidx, patientsplit, epilen);
foldhptable.Fold(foldhpcomb) = fold;
foldhptable(foldhpcomb, :)   = setHyperParamQSrow(foldhptable(foldhpcomb, :), lrval, ntrval, mlsval, mnsval, fvsval, pmRes);
if ~ismember(modelver, {'vPM1'})
    foldhptable(foldhpcomb, :)   = setHyperParamQSTreeInfo(foldhptable(foldhpcomb, :), mdl);
end

fprintf('\n');

end

