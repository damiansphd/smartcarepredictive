function [avgdelayreduction] = calcAvgDelayReductionForThresh(pmAMPred, featureindex, labels, pred, thresh)

% calcAvgDelayReductionForThres - calculates the average reduction in delay to
% treatment vs current clinical practice (over all interventions) for a
% given threshold level that would trigger an alert


% assume an average delay of 2 days in current clinical practice
currclindelay = 2;

patients = unique(featureindex.PatientNbr);
pmAMPred = pmAMPred(ismember(pmAMPred.PatientNbr, patients),:);
reduction = zeros(size(pmAMPred, 1), 1);
count = 0;

for i = 1:size(pmAMPred, 1)
    pnbr       = pmAMPred.PatientNbr(i);
    exstart    = pmAMPred.Pred(i);
    treatstart = pmAMPred.IVScaledDateNum(i);
    
    intrlabl = labels(featureindex.PatientNbr == pnbr & featureindex.CalcDatedn >= exstart & featureindex.CalcDatedn < treatstart);
    if ~all(intrlabl)
        fprintf('**** Not all labels are 1 for intervention %3d:%3d:%3d ****\n', pnbr, exstart, treatstart);
    end
    
    intrpred = pred(featureindex.PatientNbr == pnbr & featureindex.CalcDatedn >= exstart & featureindex.CalcDatedn < treatstart);
    
    if size(intrpred, 1) ~= 0
        triggeridx = find(intrpred >= thresh, 1, 'first');
        if size(triggeridx, 1) ~= 0
            reduction(i) = size(intrpred, 1) - currclindelay + 1 - triggeridx;
        else
            reduction(i) = 0;
        end
        count = count + 1;
    end
end

avgdelayreduction = sum(reduction) / count;

end
