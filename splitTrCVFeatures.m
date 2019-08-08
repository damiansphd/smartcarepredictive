function [pmTrFeatureIndex, pmTrMuIndex, pmTrSigmaIndex, pmTrNormFeatures, trlabels, ...
          pmCVFeatureIndex, pmCVMuIndex, pmCVSigmaIndex, pmCVNormFeatures, cvlabels, cvidx] = ...
          splitTrCVFeatures(pmTrCVFeatureIndex, pmTrCVMuIndex, pmTrCVSigmaIndex, pmTrCVNormFeatures, trcvlabels, pmTrCVPatientSplit, fold)
      
% splitTrCVFeatures - split out training and cross validation data for a
% given fold

cvidx = ismember(pmTrCVFeatureIndex.PatientNbr, pmTrCVPatientSplit.PatientNbr(pmTrCVPatientSplit.SplitNbr == fold));

pmCVFeatureIndex = pmTrCVFeatureIndex(cvidx, :);
pmCVMuIndex      = pmTrCVMuIndex(cvidx, :);
pmCVSigmaIndex   = pmTrCVSigmaIndex(cvidx, :);
pmCVNormFeatures = pmTrCVNormFeatures(cvidx, :);
cvlabels         = trcvlabels(cvidx);

pmTrFeatureIndex = pmTrCVFeatureIndex(~cvidx, :);
pmTrMuIndex      = pmTrCVMuIndex(~cvidx, :);
pmTrSigmaIndex   = pmTrCVSigmaIndex(~cvidx, :);
pmTrNormFeatures = pmTrCVNormFeatures(~cvidx, :);
trlabels         = trcvlabels(~cvidx);

end

