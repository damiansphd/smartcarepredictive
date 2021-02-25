function [idx] = getIndexForOutcome(pred, labels, fplabels, opthresh, outcome)

% getIndexForOutcome - return the index for a given model outcome (TP, TN,
% FP, FN)

switch outcome
    case 'TP'
        idx = pred >= opthresh & labels == 1;
    case 'FP'
        idx = pred >= opthresh & labels == 0;
    case 'FP1'
        idx = pred >= opthresh & labels == 0 & fplabels == 1;
    case 'FP2'
        idx = pred >= opthresh & labels == 0 & fplabels == 0;
    case 'TN'
        idx  = pred <  opthresh & labels == 0;
    case 'FN'
        idx  = pred <  opthresh & labels == 1;
end


end

