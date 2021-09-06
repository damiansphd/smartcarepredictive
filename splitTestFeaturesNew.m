function [pmTestFeatureIndex, pmTestMuIndex, pmTestSigmaIndex, pmTestNormFeatures, ...
    pmTestExABxElLabels, pmTestPatientSplit, ...
    pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, ...
    pmTrCVExABxElLabels, pmTrCVPatientSplit, nfolds, testidx] ...
    = splitTestFeaturesNew(pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmNormFeatures, pmExABxElLabels, pmPatientSplit, nsplits)
      
% splitTestFeaturesNew - split out test data from training & cross validation
% data - for version with interpolation fix

testidx = ismember(pmFeatureIndex.PatientNbr, pmPatientSplit.PatientNbr(pmPatientSplit.SplitNbr == nsplits));

pmTrCVPatientSplit = pmPatientSplit(pmPatientSplit.SplitNbr ~= nsplits, :);
pmTestPatientSplit = pmPatientSplit(pmPatientSplit.SplitNbr == nsplits, :);

nfolds = max(pmTrCVPatientSplit.SplitNbr);


pmTestFeatureIndex = pmFeatureIndex(testidx, :);
pmTestMuIndex      = pmMuIndex(testidx, :);
pmTestSigmaIndex   = pmSigmaIndex(testidx, :);
pmTestNormFeatures = pmNormFeatures(testidx, :);

pmTestExABxElLabels = pmExABxElLabels(testidx, :);

pmTrCVFeatureIndex = pmFeatureIndex(~testidx, :);
pmTrCVMuIndex      = pmMuIndex(~testidx, :);
pmTrCVSigmaIndex   = pmSigmaIndex(~testidx, :);
pmTrCVNormFeatures = pmNormFeatures(~testidx, :);

pmTrCVExABxElLabels = pmExABxElLabels(~testidx, :);

end

