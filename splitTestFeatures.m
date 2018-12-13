function [pmTestFeatureIndex, pmTestFeatures, pmTestNormFeatures, pmTestIVLabels, pmTestExLabels, pmTestABLabels, pmTestExLBLabels, ...
          pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVABLabels, pmTrCVExLBLabels, ...
          pmTrCVPatientSplit, nfolds] = ...
            splitTestFeatures(pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmExLabels, pmABLabels, pmExLBLabels, pmPatientSplit, nsplits)
      
% splitTestFeatures - split out test data from training & cross validation
% data

testidx = ismember(pmFeatureIndex.PatientNbr, pmPatientSplit.PatientNbr(pmPatientSplit.SplitNbr == nsplits));

pmTrCVPatientSplit = pmPatientSplit(pmPatientSplit.SplitNbr ~= nsplits, :);
nfolds = max(pmTrCVPatientSplit.SplitNbr);


pmTestFeatureIndex = pmFeatureIndex(testidx, :);
pmTestFeatures     = pmFeatures(testidx, :);
pmTestNormFeatures = pmNormFeatures(testidx, :);
pmTestIVLabels     = pmIVLabels(testidx, :);
pmTestExLabels     = pmExLabels(testidx, :);
pmTestABLabels     = pmABLabels(testidx, :);
pmTestExLBLabels   = pmExLBLabels(testidx, :);

pmTrCVFeatureIndex = pmFeatureIndex(~testidx, :);
pmTrCVFeatures     = pmFeatures(~testidx, :);
pmTrCVNormFeatures = pmNormFeatures(~testidx, :);
pmTrCVIVLabels     = pmIVLabels(~testidx, :);
pmTrCVExLabels     = pmExLabels(~testidx, :);
pmTrCVABLabels     = pmABLabels(~testidx, :);
pmTrCVExLBLabels   = pmExLBLabels(~testidx, :);

end

