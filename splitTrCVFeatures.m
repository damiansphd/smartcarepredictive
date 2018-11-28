function [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, pmTrIVLabels, pmTrExLabels, ...
          pmCVFeatureIndex, pmCVFeatures, pmCVNormFeatures, pmCVIVLabels, pmCVExLabels, cvidx] = ...
          splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, pmTrCVIVLabels, pmTrCVExLabels, pmTrCVPatientSplit, fold)
      
% splitTrCVFeatures - split out training and cross validation data for a
% given fold

cvidx = ismember(pmTrCVFeatureIndex.PatientNbr, pmTrCVPatientSplit.PatientNbr(pmTrCVPatientSplit.SplitNbr == fold));

pmCVFeatureIndex = pmTrCVFeatureIndex(cvidx, :);
pmCVFeatures     = pmTrCVFeatures(cvidx, :);
pmCVNormFeatures = pmTrCVNormFeatures(cvidx, :);
pmCVIVLabels     = pmTrCVIVLabels(cvidx, :);
pmCVExLabels     = pmTrCVExLabels(cvidx, :);

pmTrFeatureIndex = pmTrCVFeatureIndex(~cvidx, :);
pmTrFeatures     = pmTrCVFeatures(~cvidx, :);
pmTrNormFeatures = pmTrCVNormFeatures(~cvidx, :);
pmTrIVLabels     = pmTrCVIVLabels(~cvidx, :);
pmTrExLabels     = pmTrCVExLabels(~cvidx, :);

end

