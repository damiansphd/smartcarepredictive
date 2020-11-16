function [pmTrMPIndex, pmTrMPArray, pmTrMPQS, trlabels, ...
          pmCVMPIndex, pmCVMPArray, pmCVMPQS, cvlabels, cvidx] ...
            = splitTrCVQCFeats(pmMissPattIndex, pmMissPattArray, pmMissPattQS, labels, qcsplitidx, fold)
        
% splitTrCVMPFeats - splits out training vs cross val examples for a given
% fold for the missingness pattern dataset

cvidx = (qcsplitidx == fold);

pmCVMPIndex = pmMissPattIndex(cvidx, :);
pmCVMPArray = pmMissPattArray(cvidx, :);
pmCVMPQS    = pmMissPattQS(cvidx, :);
cvlabels    = labels(cvidx);

pmTrMPIndex = pmMissPattIndex(~cvidx, :);
pmTrMPArray = pmMissPattArray(~cvidx, :);
pmTrMPQS    = pmMissPattQS(~cvidx, :);
trlabels    = labels(~cvidx);

end

