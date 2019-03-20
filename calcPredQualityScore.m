function [mdlres, pmampred] = calcPredQualityScore(mdlres, labels, nexamples, pmampred, featidx, patientsplit)

% calcPredQualityScore - calculates score based on number of high.
% medium, low scores, separately for regular treatments (reward high predictions) 
% and elective treatments (reward low predictions)

pmampred = getPredictedIntr(pmampred, featidx, patientsplit, mdlres);

% set threshold dividers for high, medium and low prediction buckets
hthres = 0.5;
mthres = 0.15;

idx = pmampred.ElectiveTreatment ~= 'Y';
mdlres.HighP  = sum((pmampred.MaxPred(idx) >= hthres),1);
mdlres.MedP   = sum((pmampred.MaxPred(idx) <  hthres & pmampred.MaxPred(idx) >= mthres),1);
mdlres.LowP   = sum((pmampred.MaxPred(idx) <  mthres),1);
mdlres.PScore = 100 * (mdlres.HighP + (0.5 * mdlres.MedP)) / sum(idx,1);

idx = pmampred.ElectiveTreatment == 'Y';
mdlres.ElecHighP  = sum((pmampred.MaxPred(idx) >= hthres),1);
mdlres.ElecMedP   = sum((pmampred.MaxPred(idx) <  hthres & pmampred.MaxPred(idx) >= mthres),1);
mdlres.ElecLowP   = sum((pmampred.MaxPred(idx) <  mthres),1);
mdlres.ElecPScore = 100 * (mdlres.ElecLowP + (0.5 * mdlres.ElecMedP)) / sum(idx,1);

fprintf('PScore = %.1f%% (%d/%d/%d), ElecPScore = %.1f%% (%d/%d/%d) ', mdlres.PScore, mdlres.HighP, ...
    mdlres.MedP, mdlres.LowP, mdlres.ElecPScore, mdlres.ElecHighP, mdlres.ElecMedP, mdlres.ElecLowP);

end

