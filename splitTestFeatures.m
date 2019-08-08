function [pmTestFeatureIndex, pmTestMuIndex, pmTestSigmaIndex, pmTestNormFeatures, ...
    pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, pmTestExABLabels, pmTestExABxElLabels, ...
    pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, ...
    pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, pmTrCVExABLabels, pmTrCVExABxElLabels,...
    pmTrCVPatientSplit, nfolds] ...
    = splitTestFeatures(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmNormFeatures, pmIVLabels, ...
                        pmExLabels, pmABLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels, pmPatientSplit, nsplits)
      
% splitTestFeatures - split out test data from training & cross validation
% data

testidx = ismember(pmFeatureIndex.PatientNbr, pmPatientSplit.PatientNbr(pmPatientSplit.SplitNbr == nsplits));

pmTrCVPatientSplit = pmPatientSplit(pmPatientSplit.SplitNbr ~= nsplits, :);
nfolds = max(pmTrCVPatientSplit.SplitNbr);


pmTestFeatureIndex = pmFeatureIndex(testidx, :);
pmTestMuIndex      = pmMuIndex(testidx, :);
pmTestSigmaIndex   = pmSigmaIndex(testidx, :);
pmTestNormFeatures = pmNormFeatures(testidx, :);
pmTestIVLabels     = pmIVLabels(testidx, :);
pmTestExLabels     = pmExLabels(testidx, :);
pmTestABLabels     = pmABLabels(testidx, :);
pmTestExLBLabels   = pmExLBLabels(testidx, :);
pmTestExABLabels   = pmExABLabels(testidx, :);
pmTestExABxElLabels   = pmExABxElLabels(testidx, :);

pmTrCVFeatureIndex = pmFeatureIndex(~testidx, :);
pmTrCVMuIndex      = pmMuIndex(~testidx, :);
pmTrCVSigmaIndex   = pmSigmaIndex(~testidx, :);
pmTrCVNormFeatures = pmNormFeatures(~testidx, :);
pmTrCVIVLabels     = pmIVLabels(~testidx, :);
pmTrCVExLabels     = pmExLabels(~testidx, :);
pmTrCVABLabels     = pmABLabels(~testidx, :);
pmTrCVExLBLabels   = pmExLBLabels(~testidx, :);
pmTrCVExABLabels   = pmExABLabels(~testidx, :);
pmTrCVExABxElLabels   = pmExABxElLabels(~testidx, :);

end

