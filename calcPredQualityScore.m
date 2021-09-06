function [mdlres, pmampredupd] = calcPredQualityScore(mdlres, pmampred, featidx, patientsplit)

% calcPredQualityScore - calculates score based on number of high.
% medium, low scores, separately for regular treatments (reward high predictions) 
% and elective treatments (reward low predictions)

pmampredupd = getPredictedIntr(pmampred, featidx, patientsplit, mdlres);

% set threshold dividers for high, medium and low prediction buckets
hthres = 0.5;
mthres = 0.15;

idx = pmampredupd.ElectiveTreatment ~= 'Y';
mdlres.HighP  = sum((pmampredupd.MaxPred(idx) >= hthres),1);
mdlres.MedP   = sum((pmampredupd.MaxPred(idx) <  hthres & pmampredupd.MaxPred(idx) >= mthres),1);
mdlres.LowP   = sum((pmampredupd.MaxPred(idx) <  mthres),1);
mdlres.PScore = 100 * (mdlres.HighP + (0.5 * mdlres.MedP)) / sum(idx,1);

idx = pmampredupd.ElectiveTreatment == 'Y';
if sum(idx, 1) > 0
    mdlres.ElecHighP  = sum((pmampredupd.MaxPred(idx) >= hthres),1);
    mdlres.ElecMedP   = sum((pmampredupd.MaxPred(idx) <  hthres & pmampredupd.MaxPred(idx) >= mthres),1);
    mdlres.ElecLowP   = sum((pmampredupd.MaxPred(idx) <  mthres),1);
    mdlres.ElecPScore = 100 * (mdlres.ElecLowP + (0.5 * mdlres.ElecMedP)) / sum(idx,1);
else
    mdlres.ElecHighP  = 0;
    mdlres.ElecMedP   = 0;
    mdlres.ElecLowP   = 0;
    mdlres.ElecPScore = 100;
end

fprintf('PScore = %.1f%% (%d/%d/%d), ElecPScore = %.1f%% (%d/%d/%d)\n', mdlres.PScore, mdlres.HighP, ...
    mdlres.MedP, mdlres.LowP, mdlres.ElecPScore, mdlres.ElecHighP, mdlres.ElecMedP, mdlres.ElecLowP);

end

