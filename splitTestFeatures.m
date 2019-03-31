function [pmTestFeatureIndex, pmTestNormFeatures, ...
    pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, pmTestExABLabels, ...
    pmTrCVFeatureIndex, pmTrCVNormFeatures, ...
    pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, ...
    pmTrCVPatientSplit, nfolds] ...
    = splitTestFeatures(pmFeatureIndex, pmNormFeatures, pmIVLabels, ...
                        pmExLabels, pmABLabels, pmExLBLabels, pmExABLabels, pmPatientSplit, nsplits)
      
% splitTestFeatures - split out test data from training & cross validation
% data

testidx = ismember(pmFeatureIndex.PatientNbr, pmPatientSplit.PatientNbr(pmPatientSplit.SplitNbr == nsplits));

pmTrCVPatientSplit = pmPatientSplit(pmPatientSplit.SplitNbr ~= nsplits, :);
nfolds = max(pmTrCVPatientSplit.SplitNbr);


pmTestFeatureIndex = pmFeatureIndex(testidx, :);
pmTestNormFeatures = pmNormFeatures(testidx, :);
pmTestIVLabels     = pmIVLabels(testidx, :);
pmTestExLabels     = pmExLabels(testidx, :);
pmTestABLabels     = pmABLabels(testidx, :);
pmTestExLBLabels   = pmExLBLabels(testidx, :);
pmTestExABLabels   = pmExABLabels(testidx, :);

pmTrCVFeatureIndex = pmFeatureIndex(~testidx, :);
pmTrCVNormFeatures = pmNormFeatures(~testidx, :);
pmTrCVIVLabels     = pmIVLabels(~testidx, :);
pmTrCVExLabels     = pmExLabels(~testidx, :);
pmTrCVABLabels     = pmABLabels(~testidx, :);
pmTrCVExLBLabels   = pmExLBLabels(~testidx, :);
pmTrCVExABLabels   = pmExABLabels(~testidx, :);

end

