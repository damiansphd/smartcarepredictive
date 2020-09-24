function [pmTrMPIndex, pmTrMPArray, pmTrMPQS, trlabels, ...
          pmCVMPIndex, pmCVMPArray, pmCVMPQS, cvlabels, cvidx] ...
            = splitTrCVMPFeats(pmTrCVMPIndex, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, trcvmpsplitidx, fold)
        
% splitTrCVMPFeats - splits out training vs cross val examples for a given
% fold for the missingness pattern dataset

cvidx = trcvmpsplitidx == fold;

pmCVMPIndex = pmTrCVMPIndex(cvidx, :);
pmCVMPArray = pmTrCVMPArray(cvidx, :);
pmCVMPQS    = pmTrCVMPQS(cvidx, :);
cvlabels    = trcvlabels(cvidx);

pmTrMPIndex = pmTrCVMPIndex(~cvidx, :);
pmTrMPArray = pmTrCVMPArray(~cvidx, :);
pmTrMPQS    = pmTrCVMPQS(~cvidx, :);
trlabels    = trcvlabels(~cvidx);

end

