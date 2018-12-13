function [pmTrFeatureIndex, pmTrFeatures, pmTrNormFeatures, trlabels, ...
          pmCVFeatureIndex, pmCVFeatures, pmCVNormFeatures, cvlabels, cvidx] = ...
          splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVFeatures, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold)
      
% splitTrCVFeatures - split out training and cross validation data for a
% given fold

cvidx = ismember(pmTrCVFeatureIndex.PatientNbr, pmTrCVPatientSplit.PatientNbr(pmTrCVPatientSplit.SplitNbr == fold));

pmCVFeatureIndex = pmTrCVFeatureIndex(cvidx, :);
pmCVFeatures     = pmTrCVFeatures(cvidx, :);
pmCVNormFeatures = pmTrCVNormFeatures(cvidx, :);
cvlabels         = trcvlabels(cvidx);

pmTrFeatureIndex = pmTrCVFeatureIndex(~cvidx, :);
pmTrFeatures     = pmTrCVFeatures(~cvidx, :);
pmTrNormFeatures = pmTrCVNormFeatures(~cvidx, :);
trlabels         = trcvlabels(~cvidx);

end

