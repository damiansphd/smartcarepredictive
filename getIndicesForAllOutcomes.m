function [tpidx, fpidx, fp1idx, fp2idx, tnidx, fnidx] = getIndicesForAllOutcomes(pred, labels, qsarray, opthresh, fpthresh)

% getIndicesForAllOutcomes - convenience function to return index arrays
% for all outcomes

tpidx  = getIndexForOutcome(pred, labels, qsarray, opthresh, fpthresh / 100, 'TP');
fpidx  = getIndexForOutcome(pred, labels, qsarray, opthresh, fpthresh / 100, 'FP');
fp1idx = getIndexForOutcome(pred, labels, qsarray, opthresh, fpthresh / 100, 'FP1');
fp2idx = getIndexForOutcome(pred, labels, qsarray, opthresh, fpthresh / 100, 'FP2');
tnidx  = getIndexForOutcome(pred, labels, qsarray, opthresh, fpthresh / 100, 'TN');
fnidx  = getIndexForOutcome(pred, labels, qsarray, opthresh, fpthresh / 100, 'FN');

end

