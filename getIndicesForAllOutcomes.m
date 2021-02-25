function [tpidx, fpidx, fp1idx, fp2idx, tnidx, fnidx] = getIndicesForAllOutcomes(pred, labels, fplabels, opthresh)

% getIndicesForAllOutcomes - convenience function to return index arrays
% for all outcomes

tpidx  = getIndexForOutcome(pred, labels, fplabels, opthresh, 'TP');
fpidx  = getIndexForOutcome(pred, labels, fplabels, opthresh, 'FP');
fp1idx = getIndexForOutcome(pred, labels, fplabels, opthresh, 'FP1');
fp2idx = getIndexForOutcome(pred, labels, fplabels, opthresh, 'FP2');
tnidx  = getIndexForOutcome(pred, labels, fplabels, opthresh, 'TN');
fnidx  = getIndexForOutcome(pred, labels, fplabels, opthresh, 'FN');

end

