function [pmTrFeatureIndex, pmTrNormFeatures, trlabels, ...
          pmCVFeatureIndex, pmCVNormFeatures, cvlabels, cvidx] = ...
          splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold)
      
% splitTrCVFeatures - split out training and cross validation data for a
% given fold

cvidx = ismember(pmTrCVFeatureIndex.PatientNbr, pmTrCVPatientSplit.PatientNbr(pmTrCVPatientSplit.SplitNbr == fold));

pmCVFeatureIndex = pmTrCVFeatureIndex(cvidx, :);
pmCVNormFeatures = pmTrCVNormFeatures(cvidx, :);
cvlabels         = trcvlabels(cvidx);

pmTrFeatureIndex = pmTrCVFeatureIndex(~cvidx, :);
pmTrNormFeatures = pmTrCVNormFeatures(~cvidx, :);
trlabels         = trcvlabels(~cvidx);

end

