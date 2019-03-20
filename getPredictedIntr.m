function [pmampredtest] = getPredictedIntr(pmampred, pmTrCVFeatureIndex, pmTrCVPatientSplit, modeldayres)

% getPredictedIntr - returns the subset of interventiosn that were
% predicted, along with their mean, median, and max predictions

ninterventions = size(pmampred,1);
pmampredtest = pmampred;

pmampredtest.SplitNbr(:) = -1.0;
pmampredtest.IntrDuration(:) = -1.0;
pmampredtest.MeanPred(:) = -1.0;
pmampredtest.MedianPred(:) = -1.0;
pmampredtest.MaxPred(:) = -1.0;
pmampredtest.MaxPredDay(:) = -1.0;

for i = 1:ninterventions
    pnbr = pmampredtest.PatientNbr(i);
    exstart = pmampredtest.Pred(i);
    ivstart = pmampredtest.IVScaledDateNum(i);
    intridx = pmTrCVFeatureIndex.PatientNbr == pnbr & pmTrCVFeatureIndex.CalcDatedn >= exstart & pmTrCVFeatureIndex.CalcDatedn < ivstart;
    if sum(intridx) ~= 0
        pmampredtest.SplitNbr(i) = pmTrCVPatientSplit.SplitNbr(pmTrCVPatientSplit.PatientNbr == pnbr);
        pmampredtest.IntrDuration(i) = ivstart - exstart;
        pmampredtest.MeanPred(i)     = mean(modeldayres.Pred(intridx));
        pmampredtest.MedianPred(i)   = median(modeldayres.Pred(intridx));
        [pmampredtest.MaxPred(i), pmampredtest.MaxPredDay(i)] = max(modeldayres.Pred(intridx));
    end
end

pmampredtest(pmampredtest.MeanPred == -1,:) = [];

end

