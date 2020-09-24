function splitidx = createMPSplitIndex(nexamples, nsplits)

% createMPSplitIndex - creates an index to be used to split out held-out
% test data and folds.

idx = (1:nsplits)';
repeat = ceil(nexamples / nsplits);

splitidx = repmat(idx, repeat, 1);
splitidx = splitidx(1:nexamples);

end

