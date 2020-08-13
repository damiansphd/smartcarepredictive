function [pmampredupd] = getPredictedIntr(pmampred, featidx, patientsplit, modeldayres)

% getPredictedIntr - returns the subset of interventiosn that were
% predicted, along with their mean, median, and max predictions

ninterventions = size(pmampred,1);
pmampredupd = pmampred;

pmampredupd.SplitNbr(:) = -1.0;
pmampredupd.IntrDuration(:) = -1.0;
pmampredupd.MeanPred(:) = -1.0;
pmampredupd.MedianPred(:) = -1.0;
pmampredupd.MaxPred(:) = -1.0;
pmampredupd.MaxPredDay(:) = -1.0;

for i = 1:ninterventions
    pnbr = pmampredupd.PatientNbr(i);
    exstart = pmampredupd.Pred(i);
    ivstart = pmampredupd.IVScaledDateNum(i);
    intridx = featidx.PatientNbr == pnbr & featidx.ScenType == 0 & featidx.CalcDatedn >= exstart & featidx.CalcDatedn < ivstart;
    if sum(intridx) ~= 0
        pmampredupd.SplitNbr(i) = patientsplit.SplitNbr(patientsplit.PatientNbr == pnbr);
        pmampredupd.IntrDuration(i) = ivstart - exstart;
        pmampredupd.MeanPred(i)     = mean(modeldayres.Pred(intridx));
        pmampredupd.MedianPred(i)   = median(modeldayres.Pred(intridx));
        [pmampredupd.MaxPred(i), pmampredupd.MaxPredDay(i)] = max(modeldayres.Pred(intridx));
    end
end

pmampredupd(pmampredupd.MeanPred == -1,:) = [];

end

