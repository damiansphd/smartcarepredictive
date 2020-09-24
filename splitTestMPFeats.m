function [pmTestMPIndex, pmTestMPArray, pmTestMPQS, testlabels, testmpsplitidx, ...
    pmTrCVMPIndex, pmTrCVMPArray, pmTrCVMPQS, trcvlabels, trcvmpsplitidx, nfolds] = ...
    splitTestMPFeats(pmMissPattIndex, pmMissPattArray, pmMissPattQS, labels, mpsplitidx, nsplits)

% splitTestMPFeats - split held-out test set from TrCV set in the
% missingness pattern dataset

testidx = mpsplitidx == nsplits;

testmpsplitidx = mpsplitidx(mpsplitidx == nsplits);
trcvmpsplitidx = mpsplitidx(mpsplitidx ~= nsplits);

pmTestMPIndex = pmMissPattIndex(testidx, :);
pmTestMPArray = pmMissPattArray(testidx, :);
pmTestMPQS    = pmMissPattQS(testidx, :);
testlabels    = labels(testidx, :);

pmTrCVMPIndex = pmMissPattIndex(~testidx, :);
pmTrCVMPArray = pmMissPattArray(~testidx, :);
pmTrCVMPQS    = pmMissPattQS(~testidx, :);
trcvlabels    = labels(~testidx, :);

nfolds = nsplits - 1;

end

